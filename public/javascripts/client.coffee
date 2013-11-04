$ ->

  # for local
  socket = io.connect('http://localhost:3000')

  width = 600
  height = 400

  nodes = new Array
  links = new Array

  hideNodes = new Array
  hideTitles = new Array

  texts = new Array

  svg = d3.select('body').append('svg')
  .attr('width',width).attr('height',height)


  # force layout settings
  force = d3.layout.force()
  .nodes(nodes)
  .links(links)
  .size([width,height])
  .gravity(0.5)
  .distance(100)
  .charge(-500)

  # calculate x and y
  tick = () ->
    link.attr("x1",(d) ->
      d.source.x
    ).attr("y1",(d) ->
      d.source.y
    ).attr("x2",(d) ->
      d.target.x
    ).attr("y2",(d) ->
      d.target.y
    )
    node.attr("transform",(d) ->
      return "translate("+d.x+","+d.y+")"
    )

  # zoomIn event
  zoomIn = (json) ->
    console.log "zoomIn: "+json.text
    hideNodes = _.reject(nodes,(node) ->
      node.text is json.text
    )
    nodes.length = 0
    nodes.push(json)
    links.length = 0
    svg.selectAll("g").data(nodes).exit().remove()
    svg.selectAll("line").data(links).exit().remove()
    socket.json.emit("zoom json",json)
    update()

  # zoomOut event
  zoomOut = () ->
    console.log "zoomOut"
    nodes.length = 0

     
  # init node
  node = svg.selectAll(".node").data(nodes)
  .enter().append("g")
  .attr("class","node")
  .call(force.drag)

  link = svg.selectAll(".link").data(links)
  .enter().append("line")
  .attr("class","link")
  .style("stroke-width",1)
  .style("stroke","black")
  #force.on("tick",tick).start()

  # called every time
  update = () ->
    node = svg.selectAll(".node").data(nodes)
    node.enter().insert("g")
    .attr("class","node")
    .on("mouseover",(e) ->
      console.log e
      svg.selectAll(".link")
      .style("opacity",0)
      .filter((d,i) ->
        d.source.text is e.text or d.target.text is e.text
      ).style("opacity",1)
    ).on("mouseout",(e) ->
      svg.selectAll(".link")
      .style("opacity",0.1)
    )
    .on("click",zoomIn)
    .call(force.drag)

    # must fix
    svg.selectAll("text").remove()
    svg.selectAll("circle").remove()

    node.insert("circle")
    .attr("r",(d)->
      return Math.sqrt(d.value)
    )
    .attr("fill",(d) ->
      if d.id > 40
        return "cyan"
      else if d.id > 30
        return "blue"
      else if d.id > 20
        return "lime"
      else if d.id > 10
        return "pink"
      else
        return "orange"
    ).style("opacity",0.7)
    node.insert("text")
    .text((d) ->
      return d.text
    ).style("opacity",0.7)

    # link style
    link = svg.selectAll(".link").data(links)
    link.enter().insert("line")
    .attr("class","link")
    .style("stroke-width",1)
    .style("stroke","red")
    .style("opacity",0.1)

    force.on("tick",tick).start()

  # connection
  
  socket.on("debug",(debug)->
    console.log debug
  )
  # send node
  socket.on("send node",(json)->
    if _.contains(texts,json.text) is true
      node = _.findWhere(nodes,text:json.text)
      node.value += json.value
      update()
    # if not have
    else
      json.id = nodes.length
      nodes.push json
      texts = _.pluck(nodes,'text')
      update()
  )
  # add link
  socket.on("add link",(json) ->
    if _.has(json,"source") and _.has(json,"target")
      links.push json
      update()
    else
      console.log json
      target = json.tempTarget
      if _.contains(texts,target) is true
        json.target = _.indexOf(texts,target)
        json.source = _.indexOf(texts,json.tempSource)
        console.log json
        links.push json
        update()
  )

  $("button").click( ()->
    console.log $("#word")[0].value
    socket.emit("word",$("#word")[0].value)
  )

