###
Что делает:
 - отвечает за создание стека версий в пределах одного продукта

Как делает:
 - проходит по указанной директории
 - ищет файлы с именованием по маске semver 
 - создает кеш содержимого подходящих файлов
 - при запросе определенной версии делает мердж снизу вверх и отдает получившийся объект
 
Поведение при запросе версии:
 - если запрошеная версия БОЛЬШЕ минимальной в директории - поднимаемся до запрошенной версии включительно (если нет ТОЧНОГО соответствия - не беда)
 - если запрошенная версия МЕНЬШЕ минимальной в директории - возвращаем пустой объект + выдаем предупреждение в лог
 - если запрошенная версия БОЛЬШЕ максимальной в директории - поднимаемся до максимальной реализации + выдаем предупреждение в лог

Что возвращается на запрос версии - PLAIN-hash с методами (НЕ объект класса)

Важно! единожды инициированный объект нельзя переиспользовать по-новой

###

_     = require 'lodash'
async = require 'async'

fs    = require 'fs'
path  = require 'path'

# наш обработчик версий
semver = require 'semver'

# пока прописываем это здесь, позднее прикрутим DI
# они определенно должны быть singleton
VersionsSearcher  = require './versions_searcher'
CodeLoader        = require './code_loader'


module.exports = class VersionsStack

  constructor: (options={}) ->
    @_logger_ = options.logger ? console

    # в strict режиме кидаем ошибку при передаче невалидной версии
    @_is_strict_  = options.strict ? no 
    # включает более демократичный парсинг версий
    @_semver_loose_mode = options.strict ? yes

    @_versions_searcher_  = new VersionsSearcher logger : @_logger_
    @_code_loader_        = new CodeLoader logger : @_logger_

    # флаг для учета инициализации объекта, у нас он сложный с асинхронным обращением
    @_is_inited_ = no
    # наш кеш файлов
    @_content_cache_ = {}
    # список отсортированных по возрастанию имен известных версий
    @_known_versions_dict_ = []
    # справочник версия -> имя файла (возможно потребуется для отладки и т.п.)
    @_version_to_filename_dict = {}
    # директория в которой работаем
    @_current_dir_ = null

  ###
  Инициация стека для сбора исходников
  ###
  initStack: (dir, main_cb) =>
    @_initStack dir, main_cb

  ###
  Строит версию кода по запрошенную включительно
  ###
  buildVersion: (version) =>
    @_buildVersion version

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
  Инициализатор
  ###
  _initStack: (dir, main_cb) =>

    if @_is_inited_
      return main_cb Error "already inited with dir |#{@_current_dir_}|, abort!"

    @_is_inited_ = yes
    @_current_dir_ = dir

    # процессим директорию и получаем только валидные имена
    @_versions_searcher_.proceedDirectory dir, (err, files_dict) =>

      @_version_to_filename_dict  = files_dict
      @_known_versions_dict_      = @_getSortedVersions _.keys files_dict

      # идем за кодом, пока синхронно
      for version_name, filename of files_dict
        @_content_cache_[version_name] = @_code_loader_.loadCode path.join dir, filename

      main_cb null, this

  ###
  Сохраняем известные нам версии для последующего поиска
  ###
  _getSortedVersions: (filenames) =>
    filenames.sort semver.compare

  ###
  Разрешает версию
  ###
  _buildVersion: (version) =>
    unless @_is_inited_
      throw Error "init object first, aborted!"

    # фильтруем мусор на входе
    unless cleaned_ver = semver.clean version, @_semver_loose_mode
      @_nonSemverVersionGeted version
      return null

    #строим план для мерджа
    plan = @_getMergePlan cleaned_ver
    # и мерджим все запланированное
    @_mergeImplementation plan

  ###
  Собираем итоговую реализацию, снизу вверх
  ###
  _mergeImplementation: (plan) =>
    result = 
      executes    : {}
      resolved_at : {}

    for step in plan.reverse()
      for name, body of @_content_cache_[step] when not result.executes[name]?
        result.executes[name]     = body
        result.resolved_at[name]  = @_version_to_filename_dict[step]
        null
      null

    result

  ###
  Ищем по переданной версии список необходимых для мерджа версий
  ###
  _getMergePlan: (version) =>
    # попробуем найти место переданной версии в списке
    index = _.sortedIndex @_known_versions_dict_, version, (elem) -> semver.compare elem, version

    # проверяем на выход за границы известного нам диапазона
    if index is 0 and @_known_versions_dict_[index] isnt version
      @_rangeErrorNotify version, 'low'
    else if index is @_known_versions_dict_.length
      @_rangeErrorNotify version, 'hight'
    
    # учитывать себя - если совпадение полное
    if @_known_versions_dict_[index] is version
      index += 1

    # и отдаем план мерджа
    @_known_versions_dict_.slice 0, index

  ###
  Обрабатываем ситуацию когда нам передают что-то что не являющийся версионным указателем
  ###
  _nonSemverVersionGeted: (version) =>
    error_text = "non-semver version |#{version}|"

    if @_is_strict_
      throw Error error_text
    else
      @_logger_.warn? "WARN: #{error_text}"

  ###
  Уведомляем о выходе за границы
  ###
  _rangeErrorNotify: (version, kind) =>
    @_logger_.warn? """
                    WARN: version |#{version}| to #{kind}, known versions:
                    |#{@_known_versions_dict_.join ', '}|
                    """
