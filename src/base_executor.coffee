###

Это базовый клас исполнителя команд - его мы по факту возвращаем из фабрики

он инкапсулирует в себе несколько методов, которые выполняют всю работу на верхнем уровне абстракции

###

_ = require 'lodash'

module.exports = class BaseExecutor

  ###
  @param {Object} {logger} - logger-объект
  ###
  constructor: (in_command_object, options={}) ->
    @_logger_ = options.logger ? console
    # берем и инициируем пачкой
    [ @_executes_ , @_resolved_at_ ] = @_processInCommandObject in_command_object
    # переменные среды, используются в окружении
    @_environment_dict_ = {}
    # окружение команды (во время ее исполнения)
    @_run_environment_  = @_buildExecutesEnvironment @_executes_

  ###
  Этот метод (асинхронно) выполняет команду относительно известного ему интерфейса

  @params {Boolean}   is_lenient  (optional)  опциональный ключ - если false или отсутствует - выкинет ошибку на неизвестную команду, если true - просто undefined
  @params {String}    command                 команда
  @params {Any}       args        (optional)  аргументы
  @params {Function}  cb                      calback
  ###
  execute : (args...) =>
    [is_lenient, new_args] = @_separateIsLenient args...
    @_executeCommand is_lenient, new_args...

  ###
  Этот метод синхронно выполняет команду относительно известного ему интерфейса
  
  @params {Boolean}   is_lenient (optional)   опциональный ключ - если false или отсутствует - выкинет ошибку на неизвестную команду, если true - просто undefined
  @params {String}    command                 команда
  @params {Any}       args        (optional)  аргументы
  ###
  executeSync : (args...) =>
    [is_lenient, new_args] = @_separateIsLenient args...
    @_executeCommandSync is_lenient, new_args...

  ###
  Проверяет существует ли такая команада

  @params {String} command  имя команды для проверки
  ###
  isCommandExists : (command) =>
    @_isCommandExists command

  ###
  Сообщает в какой версии была разрешена команда

  @params {String} command  имя команды для проверки
  ###
  whereResolved : (command) =>
    @_whereResolved command

  ###
  Возвращает полный список команд с версией, в которой они были разрешены
  (будет полезно для теста)
  ###
  getFullResolvedList : =>
    @_resolved_at_

  ###
  Возвращает значение для одного параметра из окружения среды исполнения команды
  (не клонирует, так что изменять их не следует) - подумать на эту тему

  @params {String} key ключ по которому нужен параметр
  @return {Mixed}
  ###
  getRuntimeEnvValue : (key) =>
    # WTF @meettya еще один WAT от js - две одинаковые записи неодинаковые
    @_getRuntimeEnv([key])[key]

  ###
  Возвращает объект с параметрами из окружения среды исполнения команды
  (не клонирует, так что изменять их не следует) - подумать на эту тему

  @params {Mixed} keys ключ/список ключей/массив со списком ключей
  @return {Object}
  ###
  getRuntimeEnv : (keys...) =>
    keys = keys[0] if _.isArray keys[0]
    @_getRuntimeEnv keys

  ###
  Устанавливает окружение среды исполнения команды

  @param {Object} env_object объект со свойствами среды исполнения 
  ###
  setRuntimeEnv : (env_object) =>
    @_setRuntimeEnv env_object
    this

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
  Собщает в какой версии была разрешена команда
  ###
  _whereResolved : (command) =>
    unless @_isCommandExists command
      throw ReferenceError @_unknownCommandErrorString command

    @_resolved_at_[command]

  ###
  Возвращает объектом все значения
  ###
  _getRuntimeEnv: (keys) =>
    _.reduce keys, ( (acc, key) -> acc[key] = @_environment_dict_[key]; acc ), {}, this

  ###
  Устанавливает (дополняет) словарь окружения среды исполнения
  ###
  _setRuntimeEnv : (new_env_obj) =>
    unless _.isPlainObject new_env_obj
      throw Error "environment must be plain object, but get |#{new_env_obj}|"
    @_environment_dict_ = _.assign @_environment_dict_, new_env_obj

  ###
  Возвращает список зарезервиннованных слов
  ###
  _getReservedIdentifiersList: =>
    # пока это одно и то же, но возможно будет что-то еще
    @_getAddonInjectionsMethodsList()

  ###
  Проверяет нет ли во входящем объекте использования зарезервированных слов
  ###
  _isReservedIdentifiersUsed : (in_list) =>
    intersected = _.intersection in_list, @_getReservedIdentifiersList()

    if _.isEmpty intersected
      null
    else 
      intersected

  ###
  Список методов, которые будут инжектится в окружение
  ###
  _getAddonInjectionsMethodsList : ->
    [
      'getRuntimeEnv'
      'getRuntimeEnvValue'
      'setRuntimeEnv'
      'isCommandExists'
    ]

  ###
  Возвращает объект с дополнением для среды окружения, оно будет в него подмешиваться
  ###
  _getEnvironmentAddon: =>

    reduced_fn = (acc, method_name) -> 
      acc[method_name] = _.bind @[method_name], this
      acc

    _.reduce @_getAddonInjectionsMethodsList(), reduced_fn, {}, this

  ###
  Строит окружение для исполняемого кода
  по сути дополняет полученное из файлов ссылкой на методы разрешения значений окружения
  ###
  _buildExecutesEnvironment: (executes) =>
    _.assign {}, executes, @_getEnvironmentAddon()

  ###
  Вычлиняет ключ strict-режима из вызова
  ###
  _separateIsLenient: (is_lenient, args...) ->
    unless _.isBoolean is_lenient
      args.unshift is_lenient
      is_lenient = false

    [is_lenient, args]

  ###
  Этот метод процессит входящий объект с методами
  ###
  _processInCommandObject : (in_command_object) =>
    # мусор на входе не пройдет!
    unless in_command_object.executes? or in_command_object.resolved_at?
      throw Error "command object MUST have keys `executes` and `resolved_at` but get |#{in_command_object}|"

    if intersected = @_isReservedIdentifiersUsed _.keys in_command_object.executes
      throw Error @_getReservedIdentifiersErrorText intersected, in_command_object.resolved_at

    [
      in_command_object.executes
      in_command_object.resolved_at
    ]

  ###
  Формирует текст ошибки при использовании зарезервированных слов
  ###
  _getReservedIdentifiersErrorText: (intersected, resolved_at) =>
    words_list = for identifier in intersected
      "|#{identifier}| from |#{resolved_at[identifier]}|"

    """
    reserved identifier used:
    * #{words_list.join "\n"}
    abort!
    full reserved identifiers list:
    #{@_getReservedIdentifiersList().join ', '}
    """

  ###
  Внутренний метод, делающий всю работу
  ###
  _executeCommand : (is_lenient, command, options..., cb) =>
    # простите, но только так
    unless _.isFunction cb
      throw TypeError "callback not a function! |#{cb}|" 

    unless @_isCommandExists command
      if is_lenient
        @_logger_.warn? @_unknownCommandErrorString command
        return cb null, undefined
      else
        return cb ReferenceError @_unknownCommandErrorString command

    @_executes_[command].apply @_run_environment_, options.concat cb 

  ###
  Cинхронный Внутренний метод, делающий всю работу
  ###
  _executeCommandSync : (is_lenient, command, options...) =>

    unless @_isCommandExists command
      if is_lenient
        @_logger_.warn? @_unknownCommandErrorString command
        return undefined 
      else
        throw ReferenceError @_unknownCommandErrorString command

    @_executes_[command].apply @_run_environment_, options

  ###
  Этот метод вернет нам строку ошибки, что метод нам неизвестен
  ###
  _unknownCommandErrorString: (command) =>
    "dont know command |#{command}|, known list are |#{_.keys(@_executes_).join ', '}|"

  ###
  Проверка на то, что мы знаем эту команду
  ###
  _isCommandExists: (command) =>
    # пока так по-простому
    # позднее добавим отдельную функцию на fuzzy-подсказку в стиле git если case не тот или опечатка
    !!@_executes_[command]?
