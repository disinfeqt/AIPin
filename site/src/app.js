// AIPin website: language toggle and copy buttons.
(function () {
  'use strict';

  var root = document.documentElement;

  var META = {
    'zh-CN': {
      title: 'AIPin — 魔兽世界：Forever 地图标记插件',
      description: '《魔兽世界：Forever》插件：让 AI 助手把 NPC 和地点标在你的游戏地图上，并读取你的角色信息。'
    },
    en: {
      title: 'AIPin — map pins for World of Warcraft: Forever',
      description: 'A World of Warcraft: Forever addon that lets your AI assistant pin NPCs and places on your map and read your character info.'
    }
  };

  function setLang(lang) {
    if (!META[lang]) lang = 'zh-CN';
    root.lang = lang;
    document.title = META[lang].title;
    var desc = document.querySelector('meta[name="description"]');
    if (desc) desc.setAttribute('content', META[lang].description);
    document.querySelectorAll('[data-set-lang]').forEach(function (btn) {
      btn.setAttribute('aria-pressed', String(btn.getAttribute('data-set-lang') === lang));
    });
  }

  setLang(root.lang);
  document.querySelectorAll('[data-set-lang]').forEach(function (btn) {
    btn.addEventListener('click', function () {
      var lang = btn.getAttribute('data-set-lang');
      setLang(lang);
      try { localStorage.setItem('aipin-lang', lang); } catch (e) {}
      try {
        var url = new URL(location.href);
        if (lang === 'en') url.searchParams.set('lang', 'en');
        else url.searchParams.delete('lang');
        history.replaceState(null, '', url);
      } catch (e) {}
    });
  });

  // Copy buttons for .code[data-copy]. A block may hold one <code> per
  // language; copy the one that is shown.
  function shownCode(block) {
    var codes = block.querySelectorAll('pre code');
    for (var i = 0; i < codes.length; i++) {
      var lang = codes[i].getAttribute('lang');
      if (!lang || lang === root.lang) return codes[i];
    }
    return codes[0];
  }

  function copyText(text) {
    if (navigator.clipboard && window.isSecureContext) return navigator.clipboard.writeText(text);
    return new Promise(function (resolve, reject) {
      var area = document.createElement('textarea');
      area.value = text;
      area.style.position = 'fixed';
      area.style.opacity = '0';
      document.body.appendChild(area);
      area.select();
      var ok = false;
      try { ok = document.execCommand('copy'); } catch (e) {}
      document.body.removeChild(area);
      ok ? resolve() : reject(new Error('copy failed'));
    });
  }

  document.querySelectorAll('.code[data-copy]').forEach(function (block) {
    var head = block.querySelector('.code-head');
    if (!head) return;
    var btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'copy-btn';
    btn.innerHTML =
      '<span class="idle"><span lang="zh-CN">复制</span><span lang="en">Copy</span></span>' +
      '<span class="done"><span lang="zh-CN">已复制</span><span lang="en">Copied</span></span>';
    var timer;
    btn.addEventListener('click', function () {
      var code = shownCode(block);
      if (!code) return;
      copyText(code.textContent).then(function () {
        btn.classList.add('is-done');
        clearTimeout(timer);
        timer = setTimeout(function () { btn.classList.remove('is-done'); }, 1500);
      }, function () {});
    });
    head.appendChild(btn);
  });

  // Hero button that copies the AI setup prompt shown under it, in the current language.
  document.querySelectorAll('[data-copy-prompt]').forEach(function (btn) {
    var box = document.getElementById(btn.getAttribute('data-copy-prompt'));
    if (!box) return;
    var timer;
    btn.addEventListener('click', function () {
      var srcs = box.querySelectorAll('[data-copy-src]');
      var src = srcs[0];
      for (var i = 0; i < srcs.length; i++) {
        var owner = srcs[i].closest('[lang]');
        if (owner && owner.getAttribute('lang') === root.lang) { src = srcs[i]; break; }
      }
      if (!src) return;
      copyText(src.textContent.replace(/\s+/g, ' ').trim()).then(function () {
        btn.classList.add('is-done');
        clearTimeout(timer);
        timer = setTimeout(function () { btn.classList.remove('is-done'); }, 2000);
      }, function () {});
    });
  });
})();
