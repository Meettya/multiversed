// Generated by CoffeeScript 1.9.3

/*
Что делает:
 - отвечает за поиск продуктов (подкаталогов указанного родительского)

Как делает:
 - проходит по указанной директории
 - ищет под-директории 

(возможно позднее стоит прикрутить сюда фильтр - если в под-директории нет ничего ценного - не возвращать ее вообще)
 */

(function() {
  var ProductsSearcher, _, async, fs, path,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  _ = require('lodash');

  async = require('async');

  fs = require('fs');

  path = require('path');

  module.exports = ProductsSearcher = (function() {
    function ProductsSearcher(options) {
      var ref;
      if (options == null) {
        options = {};
      }
      this._filterDirectoriesOnly = bind(this._filterDirectoriesOnly, this);
      this._proceedDirectory = bind(this._proceedDirectory, this);
      this.proceedDirectory = bind(this.proceedDirectory, this);
      this._logger_ = (ref = options.logger) != null ? ref : console;
    }


    /*
    Процессим директорию и получаем список под-директорий
    @return {Object}
     */

    ProductsSearcher.prototype.proceedDirectory = function(dir, main_cb) {
      return this._proceedDirectory(dir, main_cb);
    };


    /*  
          ******  ******  *** *     *    *    ******* ******* 
          *     * *     *  *  *     *   * *      *    *       
          *     * *     *  *  *     *  *   *     *    *       
          ******  ******   *  *     * *     *    *    *****   
          *       *   *    *   *   *  *******    *    *       
          *       *    *   *    * *   *     *    *    *       
          *       *     * ***    *    *     *    *    *******
     */


    /*
    Запускает процесс обработки директории
     */

    ProductsSearcher.prototype._proceedDirectory = function(dir, cb) {
      return fs.readdir(dir, (function(_this) {
        return function(err, names) {
          if (err != null) {
            return cb(err);
          }
          return _this._filterDirectoriesOnly(dir, names, function(products) {
            return cb(null, products);
          });
        };
      })(this));
    };


    /*
    Фильтр, вернет только файлы 
    нам не нужны под-директории и т.п.
     */

    ProductsSearcher.prototype._filterDirectoriesOnly = function(dir, files, cb) {
      var filter_fn;
      filter_fn = function(filename, a_cb) {
        return fs.stat(path.join(dir, filename), function(err, stats) {
          return a_cb(err != null ? false : stats.isDirectory());
        });
      };
      return async.filter(files, filter_fn, cb);
    };

    return ProductsSearcher;

  })();

}).call(this);
