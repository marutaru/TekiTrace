// Generated by CoffeeScript 1.6.2
(function() {
  $(function() {
    var force, height, hideNodes, hideTitles, link, links, node, nodes, socket, svg, texts, tick, update, width, zoomIn, zoomOut;

    socket = io.connect('http://localhost:3000');
    width = 800;
    height = 800;
    nodes = new Array;
    links = new Array;
    hideNodes = new Array;
    hideTitles = new Array;
    texts = new Array;
    svg = d3.select('body').append('svg').attr('width', width).attr('height', height);
    force = d3.layout.force().nodes(nodes).links(links).size([width, height]).gravity(0.5).distance(300).charge(-200);
    tick = function() {
      link.attr("x1", function(d) {
        return d.source.x;
      }).attr("y1", function(d) {
        return d.source.y;
      }).attr("x2", function(d) {
        return d.target.x;
      }).attr("y2", function(d) {
        return d.target.y;
      });
      return node.attr("transform", function(d) {
        return "translate(" + d.x + "," + d.y + ")";
      });
    };
    zoomIn = function(json) {
      console.log("zoomIn: " + json.text);
      hideNodes = _.reject(nodes, function(node) {
        return node.text === json.text;
      });
      nodes.length = 0;
      nodes.push(json);
      links.length = 0;
      svg.selectAll("g").data(nodes).exit().remove();
      svg.selectAll("line").data(links).exit().remove();
      socket.json.emit("zoom json", json);
      return update();
    };
    zoomOut = function() {
      console.log("zoomOut");
      return nodes.length = 0;
    };
    node = svg.selectAll(".node").data(nodes).enter().append("g").attr("class", "node").call(force.drag);
    link = svg.selectAll(".link").data(links).enter().append("line").attr("class", "link").style("stroke-width", 1).style("stroke", "black");
    update = function() {
      node = svg.selectAll(".node").data(nodes);
      node.enter().insert("g").attr("class", "node").on("mouseover", function(e) {
        console.log(e);
        return svg.selectAll(".link").style("opacity", 0).filter(function(d, i) {
          return d.source.text === e.text || d.target.text === e.text;
        }).style("opacity", 1);
      }).on("mouseout", function(e) {
        return svg.selectAll(".link").style("opacity", 0.0);
      }).on("click", zoomIn).call(force.drag);
      svg.selectAll("text").remove();
      svg.selectAll("circle").remove();
      node.insert("circle").attr("r", function(d) {
        return Math.sqrt(d.value);
      }).attr("fill", function(d) {
        if (d.id > 40) {
          return "cyan";
        } else if (d.id > 30) {
          return "blue";
        } else if (d.id > 20) {
          return "lime";
        } else if (d.id > 10) {
          return "pink";
        } else {
          return "orange";
        }
      }).style("opacity", 0.7);
      node.insert("text").text(function(d) {
        return d.text;
      }).style("opacity", 0.7);
      link = svg.selectAll(".link").data(links);
      link.enter().insert("line").attr("class", "link").style("stroke-width", 1).style("stroke", "red").style("opacity", 0.0);
      return force.on("tick", tick).start();
    };
    socket.on("debug", function(debug) {
      return console.log(debug);
    });
    socket.on("send node", function(json) {
      if (_.contains(texts, json.text) === true) {
        node = _.findWhere(nodes, {
          text: json.text
        });
        node.value += json.value;
        return update();
      } else {
        json.id = nodes.length;
        nodes.push(json);
        texts = _.pluck(nodes, 'text');
        return update();
      }
    });
    socket.on("add link", function(json) {
      var target;

      if (_.has(json, "source") && _.has(json, "target")) {
        links.push(json);
        return update();
      } else {
        console.log(json);
        target = json.tempTarget;
        if (_.contains(texts, target) === true) {
          json.target = _.indexOf(texts, target);
          json.source = _.indexOf(texts, json.tempSource);
          console.log(json);
          links.push(json);
          return update();
        }
      }
    });
    return $("button").click(function() {
      console.log($("#word")[0].value);
      return socket.emit("word", $("#word")[0].value);
    });
  });

}).call(this);
