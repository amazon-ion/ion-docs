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
      + '<tr><td align="center"><button id="btn-ion-parse-' + id + '">parse</button></td><td align="right"><font size="-1">made with <a href="https://github.com/amzn/ion-js">ion-js</a> (beta)</font></td></tr>'
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
      traverse(reader, 0, out, false);
    } catch (e) {
      var errorSpan = document.createElement("span");
      errorSpan.innerHTML = '<font color="red"><b>Error:  ' + e.message + '</b></font>';
      out.append(errorSpan);
    }
  };

  var containerMarkers = {
    list: "[]",
    sexp: "()",
    struct: "{}"
  };

  var traverse = function (reader, depth, out, inSexp) {
    for (var type; type = reader.next(); ) {
      indent(out, depth);
      if (reader.fieldName()) {
        out.append(reader.fieldName() + ": ");
      }

      for (let annotation of reader.annotations()) {
        out.append(annotation + "::");
      }

      if (reader.isNull()) {
        out.append("null");
        if (type.name != "null") {
          out.append("." + type.name);
        }
      } else if (type.container) {
        reader.stepIn();
        out.append(containerMarkers[type.name][0] + "\n");
        traverse(reader, depth + 1, out, type.name === "sexp");
        reader.stepOut();
        indent(out, depth);
        out.append(containerMarkers[type.name][1]);
      } else {
        switch (type.name) {
          case "blob":
            out.append("{{ /* blobs not currently supported */ }}");
            break;
          case "clob":
            out.append("{{ \"" + reader.value() + "\" }}");
            break;
          case "string":
            out.append("\"" + reader.value() + "\"");
            break;
          default:
            out.append(reader.value());
        }
      }
      if (depth > 0 && !inSexp) {
        out.append(",");
      }
      out.append("\n");
    }
  };

  var indent = function (out, depth) {
    for (var i = 0; i < depth; i++) {
      out.append("  ");
    }
  };
})()

