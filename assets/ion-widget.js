// usage:
//
//   <div class="ion-source">
//     // ion text goes here...
//     { a: 1, b: 2, c: 3 }
//   </div>
//   <script async src="ion-widget.js"/>
//
(function () {
  var script = document.createElement("script");
  script.src = "assets/ion-bundle.min.js";
  document.head.appendChild(script);

  var ionSource = document.currentScript.previousSibling.previousSibling;
  var id = Math.floor(Math.random() * 1000);
  var widget = document.createElement("div");
  widget.innerHTML
      = '<table width="100%" style="border: 0px">'
      + '<tr>'
      + '<td width="50%" style="padding: 0px">'
      + '<textarea rows="20" cols="60" id="ion-source-' + id + '" style="border: 1px solid lightgrey; background: white; color: black; padding: 5px; line-height: 1.3em">' + ionSource.innerHTML + '</textarea></td>'
      + '<td width="50%" style="padding: 0px"><code id="ion-text-' + id + '" style="display: block; white-space: pre-wrap"></code></td>'
      + '</tr>'
      + '<tr><td align="center"><button id="btn-ion-parse-' + id + '">parse</button></td><td align="right"><font size="-1">made with <a href="https://github.com/amzn/ion-js">ion-js</a></font></td></tr>'
      + '</table>';
  ionSource.parentNode.replaceChild(widget, ionSource);

  document.querySelector("#btn-ion-parse-" + id).addEventListener("click", function () {
    var source = document.getElementById("ion-source-" + id).value;
    var out = document.getElementById("ion-text-" + id);
    while (out.firstChild) {
      out.removeChild(out.firstChild);
    }
    parse(source, out);
  });

  var parse = function (source, out) {
    try {
      var reader = ion.makeReader(source);
      var writer = ion.makePrettyWriter();
      writer.writeValues(reader);
      out.append(String.fromCharCode.apply(null, writer.getBytes()));
      writer.close();
    } catch (e) {
      var errorSpan = document.createElement("span");
      errorSpan.innerHTML = '<font color="red"><b>Error:  ' + e.message + '</b></font>';
      out.append(errorSpan);
    }
  };
})()

