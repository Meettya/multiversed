###
Что делает:
 - отвечает за поиск файлов версий в пределах одного продукта

Как делает:
 - проходит по указанной директории
 - ищет файлы с именованием по маске semver 
 - компанует из них объект вида `чистое название -> имя файла`

###

_     = require 'lodash'
async = require 'async'

fs    = require 'fs'
path  = require 'path'

# наш обработчик версий
semver = require 'semver'

module.exports = class VersionSearcher

  constructor: (options={}) ->
    @_logger_ = options.logger ? console
    # в strict режиме кидаем ошибку при чтении невалидных файлов
    @_is_strict_  = options.strict ? no 
    # включает более демократичный парсинг версий
    @_semver_loose_mode = options.strict ? yes

  ###
  Процессим директорию и получаем только валидные имена
  @return {Object}
  ###
  proceedDirectory: (dir, main_cb) =>
    @_proceedDirectory dir, main_cb

  ###  
        ******  ******  *** *     *    *    ******* ******* 
        *     * *     *  *  *     *   * *      *    *       
        *     * *     *  *  *     *  *   *     *    *       
        ******  ******   *  *     * *     *    *    *****   
        *       *   *    *   *   *  *******    *    *       
        *       *    *   *    * *   *     *    *    *       
        *       *     * ***    *    *     *    *    ******* 
  ###

  ###
  Запускает процесс обработки директории
  ###
  _proceedDirectory: (dir, cb) =>
    fs.readdir dir, (err, names) =>
      return cb err if err?
      
      non_dot_started_files = @_wipeDotStartedFiles names
      # сюда фильтр только на имена
      @_filterFilesOnly dir, non_dot_started_files, (files_only) =>
        # очень далеко прокидывать флаги, проще кинуть исключение
        try
          semversed_files = @_filterSemverFilesOnly dir, files_only
        catch err
          return cb err
      
        cb null, semversed_files

  ###
  Фильтр, вернет только файлы 
  нам не нужны под-директории и т.п.
  ###
  _filterFilesOnly: (dir, files, cb) =>

    filter_fn = (filename, a_cb) ->
      fs.stat path.join( dir, filename ), (err, stats) ->
        # ну да, заметание под ковер, что поделаешь если async.filter не знает ошибок?
        a_cb if err? then false else stats.isFile()

    async.filter files, filter_fn, cb

  ###
  фильтр уберет все файлы, начинающиеся с точки
  ###
  _wipeDotStartedFiles: (files) ->
    _.reject files, (name) -> '.' is name.charAt 0

  ###
  Фильтруем только то, что валидно для semver v2.0.0
  все равно не понятно что делать с теми, кто не может быть им обработан
  ###
  _filterSemverFilesOnly: (dir, files) =>
    result = {}
    for name in files
      unless cleaned = semver.clean @_wipeFileExtension(name), @_semver_loose_mode
        @_nonSemverFilenameFinded dir, name
        continue
      result[cleaned] = name
      null

    result

  ###
  Убираем расширения файлов из их названия
  ###
  _wipeFileExtension: (filename) ->
    filename && path.basename filename, path.extname filename

  ###
  Обрабатываем ситуацию когда у нас оказывается найден файл не являющийся версионным
  ###
  _nonSemverFilenameFinded: (dir, filename) =>
    error_text = "non-semver filename |#{path.join dir, filename}|"

    if @_is_strict_
      throw Error error_text
    else
      @_logger_.warn? "WARN: #{error_text}"

