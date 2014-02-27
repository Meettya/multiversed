###
Что делает:
 - отвечает за поиск продуктов (подкаталогов указанного родительского)

Как делает:
 - проходит по указанной директории
 - ищет под-директории 

(возможно позднее стоит прикрутить сюда фильтр - если в под-директории нет ничего ценного - не возвращать ее вообще)

###

_     = require 'lodash'
async = require 'async'

fs    = require 'fs'
path  = require 'path'

module.exports = class ProductsSearcher

  constructor: (options={}) ->
    @_logger_ = options.logger ? console

  ###
  Процессим директорию и получаем список под-директорий
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
      # сюда фильтр только на имена
      @_filterDirectoriesOnly dir, names, (products) ->
        cb null, products

  ###
  Фильтр, вернет только файлы 
  нам не нужны под-директории и т.п.
  ###
  _filterDirectoriesOnly: (dir, files, cb) =>

    filter_fn = (filename, a_cb) ->
      fs.stat path.join( dir, filename ), (err, stats) ->
        # ну да, заметание под ковер, что поделаешь если async.filter не знает ошибок?
        a_cb if err? then false else stats.isDirectory()

    async.filter files, filter_fn, cb

