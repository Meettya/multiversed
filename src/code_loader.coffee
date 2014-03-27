###
Этот модуль исполняет загруженный текст, возможно используя препроцессор.

Смысл - не хочется использовать require - так как он синхронный, следовательно нужно эмулировать загрузку.
Правда если в самом модуле используется require - толку с этого не так много, как возни, но может быть и с этим что-то придумаем
###

module.exports = class CodeLoader

  constructor: (options={}) ->
    @_logger_ = options.logger ? console

  ###
  Загружает код для одного файла
  пока оставляем синхронный вариант, не будем делать вид что асинхронно выполянется
  ###
  loadCode: (full_filename) =>
    @_loadCode full_filename

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
  Сама команда
  ###
  _loadCode: (full_filename) ->
    ###
    Да, все вот так банально и синхронно
    ЧИТАТЬ ДАЛЬНЕЙШЕЕ ПЕРЕД НЕГОДОВАНИЕМ ОБЯЗАТЕЛЬНО!!!

    причина - ну прочитаем вы асинхронно указанный файл,
    начнем парсить - а там require и...? смысл в наших асинхронах?
    кроме того - используя собственный эмулятор require мы лишаем системный кеша этого файла,
    а он вполне может быть кем-то запрошен - т.е. по факту больше вреда чем пользы

    идея с РЕКУРСИВНОЙ подменой require и правкой исходников с заворачиванием их в асинхронные колбеки кажется безумной
    
    есть правда идея попробовать Clinch натравить на файлы - 
    но это для домашних экспериментов, возможно что-то из этого выгорит, попробовать (собственно, почему нет)

    Позднее посмотреть вот это на предмет асинхронной загрузки
    TODO @meettya http://stackoverflow.com/questions/13917420/node-js-load-module-async
    TODO @meettya https://github.com/webpack/enhanced-require/blob/master/lib/execModule.js

    а пока вот так

    ###
    require full_filename
