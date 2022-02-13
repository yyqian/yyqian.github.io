{%
  set js_vendors = [
    'jquery/index.js?v=2.1.3',
    'fastclick/lib/fastclick.min.js?v=1.0.6',
    'jquery_lazyload/jquery.lazyload.js?v=1.9.7',
    'velocity/velocity.min.js',
    'velocity/velocity.ui.min.js'
  ]
%}

{% if theme.fancybox %}
  {% set js_vendors[js_vendors.length] = 'fancybox/source/jquery.fancybox.pack.js' %}
{% endif %}

{# Reset `window.Promise` when it was not a function. #}
{# IE refers the element whose id is `Promise` as `window.Promise`, this causes Velocity throwing an exception #}
<script src="http://pv.sohu.com/cityjson?ie=utf-8"></script>
<script type="text/javascript">
  if (Object.prototype.toString.call(window.Promise) !== '[object Function]') {
    window.Promise = null;
  }
  function SendVisit() {
    const data = JSON.stringify({uri: window.location.href, browser: navigator.userAgent, ip: returnCitySN.cip + '|' + returnCitySN.cid + '|' + returnCitySN.cname});
    const options = {method: 'POST', body: data, headers: {'Content-Type': 'application/json'}};
    fetch('http://eagleeye.japaneast.cloudapp.azure.com:5001/visit', options).then(res => res.json());
  }
  window.onload = SendVisit();  
</script>

{% for vendor in js_vendors %}
  <script type="text/javascript" src="{{ url_for(theme.vendors) }}/{{ vendor }}"></script>
{% endfor %}
