###
Фабрика для получения объекта с набором методов.

Выглядеть результат будет как объект, реализующий доступный интерфейс 
для указанной версии указанного целевого продука

Причем для ускорения процесса определения доступности методов и избавления от глубокой цепи наследования
решили реализовывать в Java-стиле "делатель(давай-давай)".

А API оформляется плоским объектом в версиях и собирается мерджем снизу вверх,
для отсутствующих методов делаем заглушки not_implemented,
кроме того могут быть deprecated и removed - если уж совсем метод неверный

Reason d`etre - когда клиентов (пользоватлей компонента) и поставщиков (компонентов, предоставляющих данные)
становится много - нужно или делать кучу отдельных веток кода или делать компановщик
###

_     = require 'lodash'
async = require 'async'

# не всем по душе коллбеки, так что реализуем и event-based интерфейс (для инициации)
{ EventEmitter } = require 'events'

# пока прописываем это здесь, позднее прикрутим DI
ProductsStack   = require './products_stack'
# а вот это - создается на каждый запрос
BaseExecutor    = require './base_executor'

module.exports = class ComponentFactory extends EventEmitter
  
  constructor: (options={}) ->
    @_logger_ = options.logger ? console

    # в strict режиме отклонения, которые могут является ошибками-опечатками (в каталогах и т.д.) - кидают ошибку
    @_is_strict_  = options.strict ? no 

    # флаг для учета инициализации объекта, у нас он сложный с асинхронным обращением
    @_is_inited_ = no

    @_products_stack_ = new ProductsStack logger : @_logger_, strict : @_is_strict_

  ###
  Нам нужна асинхронная инициация объекта
  Как вариант - отправляем запрос на инициацию, предварительно создав слушателя

  @param {String}    dir     целевая директория
  @param {Function}  cb      (optional) callback
  ###
  initFactory: (dir, cb) =>
    @_initFactory dir, @_resultHubBuilder cb

  ###
  Этот метод строит нам интерфейс к источнику данных, соответствующий запрошенному продукту и версии

  @param {String}   product   наименование продукта
  @param {String}   version   целевая версия системы
  ###
  buildInterface: (product, version) =>
    @_buildInterface product, version

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
  По сути инициировать нужно только ProductsStack,
  все остальное потом будет разрешаться относительно него
  ###
  _initFactory: (dir, hub) =>
    if @_is_inited_
      return hub 'error', Error "already inited with dir |#{@_current_dir_}|, abort!"

    unless _.isString dir
       return hub 'error', Error "must be called with valid directory, but get |#{dir}|"

    @_is_inited_    = yes
    @_current_dir_  = dir

    # вот тут наверное можно будет как-то проверять состояние стека, что он завелся корректно
    # TODO @meettya что-то с этим сделать кроме уж совсем очевидных ошибок
    @_products_stack_.initStack dir, (err, stack) =>
      return hub 'error', err if err?
      hub 'ok', this


  ###
  Это билдер хаба для возврата клиенту результата асинхронной операции
  идея в том, что у нас может быть коллбек или слушатели или и то и другое
  ###
  _resultHubBuilder: (cb) =>
    { cb_step, listeners_step } = @_getStepsImplementations cb

    # в любом случае реализуем этот интерфейс
    steps = [listeners_step]

    if _.isFunction cb 
      steps.push cb_step
    else if _.isEmpty @listeners 'ready'
      @_logger_.warn "nobody care about inited factory, is it ok?"

    # если у нас УЖЕ есть cb-style обработчик ошибок - глушим выбрасывание исключения
    if _.isFunction(cb) and _.isEmpty @listeners 'error'
      @on 'error', (err) => @_logger_.warn err 

    (state, data) ->
      step state, data for step in steps
      null

  ###
  Возвращает реализации шагов
  ###
  _getStepsImplementations: (cb) =>
    # неизвестный вариант состояния
    unknown_state_err = (state) ->
      throw Error "unknown state |#{state}|"

    # вариант с коллбеком
    cb_step : (state, data) ->
      switch state
        when 'error'  then cb data
        when 'ok'     then cb null, data
        else 
          unknown_state_err state

    # вариант со слушателями
    listeners_step : (state, data) =>
      switch state
        when 'error'  then @emit 'error', data
        when 'ok'     then @emit 'ready', data
        else 
          unknown_state_err state

  ###
  Просто запросим это у стека продуктов и завернем в исполнитель
  ###
  _buildInterface: (product, version) =>
    unless @_is_inited_
      throw Error "init object first, aborted!"

    if @_checkArgs product, version
      raw_interface = @_products_stack_.getProduct(product).buildVersion version

      new BaseExecutor raw_interface, logger : @_logger_, strict : @_is_strict_

  ###
  Если что-то не указано - ничего не делаем ни в коем случае!
  TODO @meettya не нравится, подумать
  ###
  _checkArgs: (product, version) =>
    get_error_text = (name, value) ->
      "#{name} MUST be specified, but get |#{value}|, abort!"

    unless product
      throw Error get_error_text 'product', product

    unless version
      throw Error get_error_text 'version', version

    true
