###
Это стек продуктов, в каждом из которых имеется свой собственный стек версий

пока не совсем понятно какое api будет удачнее: 
 - buildVersion('product', 'version')
 - getProduct('product').buildVersion('version')

наверное все же композитное, но обсуждаемо

###

_     = require 'lodash'
async = require 'async'

fs    = require 'fs'
path  = require 'path'

# пока прописываем это здесь, позднее прикрутим DI
# однако это для каждого продукта - свой объект
VersionsStack   = require './versions_stack'
# вот это - точно DI
ProductsSearcher = require './products_searcher'

module.exports = class ProductsStack

  constructor: (options={}) ->
    @_logger_ = options.logger ? console

    # в strict режиме кидаем ошибку при запросе неизвестного продукта
    @_is_strict_  = options.strict ? no 

    @_products_searcher_  = new ProductsSearcher logger : @_logger_

    # флаг для учета инициализации объекта, у нас он сложный с асинхронным обращением
    @_is_inited_ = no
    # тут мы храним стеки версий по продуктам
    @_products_dict_ = {}
    # директория в которой работаем
    @_current_dir_ = null

  ###
  Инициация стека для сбора исходников
  ###
  initStack: (dir, main_cb) =>
    @_initStack dir, main_cb

  ###
  Возвращает запрошенный продукт
  ###
  getProduct: (product) =>
    @_getProduct product

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

    @_is_inited_    = yes
    @_current_dir_  = dir

    async.waterfall [
      (acb) => 
        @_products_searcher_.proceedDirectory dir, acb
      (products, acb) => 
        @_getVersionsStackAllProducts dir, products, acb
      ], (err, stacks) =>
        return main_cb err if err?

        @_products_dict_ = stacks
        return main_cb null, this

  ###
  Создает стеки версий для каждого переданного продукта

  Кстати, возможно сюда и следует впилить фильтр, чтобы два раза не парсить директории
  Позднее подумать
  ###
  _getVersionsStackAllProducts: (root_dir, products, cb) =>

    init_fn = (product, acb) =>
      versions_stack = new VersionsStack logger : @_logger_
      versions_stack.initStack path.join(root_dir, product), acb

    async.map products, init_fn, (err, versions) =>
      return cb err if err?
      cb null, _.zipObject products, versions

  ###
  Возвращает стек версий для запрошенного продукта
  ###
  _getProduct: (product) =>
    unless @_is_inited_
      throw Error "init object first, aborted!"

    unless result = @_products_dict_[product]
      throw Error @_unknownProductNotify product

    result

  ###
  Обрабатываем ситуацию когда у нас хотят продукт о котором мы не знаем
  ###
  _unknownProductNotify: (product) =>
    """
      unknown product |#{product}|, not listed in directory |#{@_current_dir_}|
      known product list:
      |#{_.keys(@_products_dict_).join ', '}|
    """

