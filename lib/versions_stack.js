// Generated by CoffeeScript 1.9.3

/*
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
 */

(function() {
  var CodeLoader, VersionsSearcher, VersionsStack, _, async, fs, path, semver,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  _ = require('lodash');

  async = require('async');

  fs = require('fs');

  path = require('path');

  semver = require('semver');

  VersionsSearcher = require('./versions_searcher');

  CodeLoader = require('./code_loader');

  module.exports = VersionsStack = (function() {
    function VersionsStack(options) {
      var ref, ref1, ref2;
      if (options == null) {
        options = {};
      }
      this._rangeErrorNotify = bind(this._rangeErrorNotify, this);
      this._nonSemverVersionGeted = bind(this._nonSemverVersionGeted, this);
      this._getMergePlan = bind(this._getMergePlan, this);
      this._mergeImplementation = bind(this._mergeImplementation, this);
      this._buildVersion = bind(this._buildVersion, this);
      this._getSortedVersions = bind(this._getSortedVersions, this);
      this._initStack = bind(this._initStack, this);
      this.buildVersion = bind(this.buildVersion, this);
      this.initStack = bind(this.initStack, this);
      this._logger_ = (ref = options.logger) != null ? ref : console;
      this._is_strict_ = (ref1 = options.strict) != null ? ref1 : false;
      this._semver_loose_mode = (ref2 = options.strict) != null ? ref2 : true;
      this._versions_searcher_ = new VersionsSearcher({
        logger: this._logger_
      });
      this._code_loader_ = new CodeLoader({
        logger: this._logger_
      });
      this._is_inited_ = false;
      this._content_cache_ = {};
      this._known_versions_dict_ = [];
      this._version_to_filename_dict = {};
      this._current_dir_ = null;
    }


    /*
    Инициация стека для сбора исходников
     */

    VersionsStack.prototype.initStack = function(dir, main_cb) {
      return this._initStack(dir, main_cb);
    };


    /*
    Строит версию кода по запрошенную включительно
     */

    VersionsStack.prototype.buildVersion = function(version) {
      return this._buildVersion(version);
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
    Инициализатор
     */

    VersionsStack.prototype._initStack = function(dir, main_cb) {
      if (this._is_inited_) {
        return main_cb(Error("already inited with dir |" + this._current_dir_ + "|, abort!"));
      }
      this._is_inited_ = true;
      this._current_dir_ = dir;
      return this._versions_searcher_.proceedDirectory(dir, (function(_this) {
        return function(err, files_dict) {
          var filename, version_name;
          _this._version_to_filename_dict = files_dict;
          _this._known_versions_dict_ = _this._getSortedVersions(_.keys(files_dict));
          for (version_name in files_dict) {
            filename = files_dict[version_name];
            _this._content_cache_[version_name] = _this._code_loader_.loadCode(path.join(dir, filename));
          }
          return main_cb(null, _this);
        };
      })(this));
    };


    /*
    Сохраняем известные нам версии для последующего поиска
     */

    VersionsStack.prototype._getSortedVersions = function(filenames) {
      return filenames.sort(semver.compare);
    };


    /*
    Разрешает версию
     */

    VersionsStack.prototype._buildVersion = function(version) {
      var cleaned_ver, plan;
      if (!this._is_inited_) {
        throw Error("init object first, aborted!");
      }
      if (!(cleaned_ver = semver.clean(version, this._semver_loose_mode))) {
        this._nonSemverVersionGeted(version);
        return null;
      }
      plan = this._getMergePlan(cleaned_ver);
      return this._mergeImplementation(plan);
    };


    /*
    Собираем итоговую реализацию, снизу вверх
     */

    VersionsStack.prototype._mergeImplementation = function(plan) {
      var body, i, len, name, ref, ref1, result, step;
      result = {
        executes: {},
        resolved_at: {}
      };
      ref = plan.reverse();
      for (i = 0, len = ref.length; i < len; i++) {
        step = ref[i];
        ref1 = this._content_cache_[step];
        for (name in ref1) {
          body = ref1[name];
          if (!(result.executes[name] == null)) {
            continue;
          }
          result.executes[name] = body;
          result.resolved_at[name] = this._version_to_filename_dict[step];
          null;
        }
        null;
      }
      return result;
    };


    /*
    Ищем по переданной версии список необходимых для мерджа версий
     */

    VersionsStack.prototype._getMergePlan = function(version) {
      var index;
      index = _.sortedIndex(this._known_versions_dict_, version, function(elem) {
        return semver.compare(elem, version);
      });
      if (index === 0 && this._known_versions_dict_[index] !== version) {
        this._rangeErrorNotify(version, 'low');
      } else if (index === this._known_versions_dict_.length) {
        this._rangeErrorNotify(version, 'hight');
      }
      if (this._known_versions_dict_[index] === version) {
        index += 1;
      }
      return this._known_versions_dict_.slice(0, index);
    };


    /*
    Обрабатываем ситуацию когда нам передают что-то что не являющийся версионным указателем
     */

    VersionsStack.prototype._nonSemverVersionGeted = function(version) {
      var base, error_text;
      error_text = "non-semver version |" + version + "|";
      if (this._is_strict_) {
        throw Error(error_text);
      } else {
        return typeof (base = this._logger_).warn === "function" ? base.warn("WARN: " + error_text) : void 0;
      }
    };


    /*
    Уведомляем о выходе за границы
     */

    VersionsStack.prototype._rangeErrorNotify = function(version, kind) {
      var base;
      return typeof (base = this._logger_).warn === "function" ? base.warn("WARN: version |" + version + "| to " + kind + ", known versions:\n|" + (this._known_versions_dict_.join(', ')) + "|") : void 0;
    };

    return VersionsStack;

  })();

}).call(this);
