express = require('express')
routes =  require('./routes')
user = require('./routes/user')
http = require('http')
path = require('path')

app = express()

auth = require('./tmp/auth')

cheerio = require('cheerio')

MeCab = require('mecab-async')
mecab = new MeCab()

_ = require('underscore')

app.set('port',process.env.PORT || 3000)
app.set('views', __dirname + '/views')
app.set('view engine','jade')
app.use(express.favicon())
app.use(express.logger('dev'))
app.use(express.bodyParser())
app.use(express.methodOverride())
app.use(app.router)
app.use(express.static(path.join(__dirname, 'public')))

if('development' == app.get('env'))
  app.use(express.errorHandler())

app.get('/',routes.index)
app.get('/users',user.list)

server = http.createServer(app).listen(app.get('port'), ()->
  console.log('Express server listening on port ' + app.get('port'))
)

dict = new Array

getListByGoogle = (socket,word,hop)->
  hop += 1
  origin =
    "text":word
    "value":5
    "part":"origin"
  socket.json.emit("send node",origin)
  options =
    hostname: 'www.google.co.jp'
    path: "/search?num=50&ie=UTF-8&oe=UTF-8&q=#{word}"
  http.get(options,(res) ->
    console.log "status"+res.statusCode
    body =''
    res.on('data',(data)->
      body += data.toString()
    )
    res.on('end',() ->
      try
        $ = cheerio.load body
        #console.log $("a").text()
        #console.log $("a")[0].data()
        src = $("a").text()
        mecab.parse(src,(err,result)->
          #console.log result

          # for google
          result = _.reject(result,(text)->
            text[0] is "キャッシュ"
          )
          result = _.reject(result,(text)->
            text[0] is "ページ"
          )
          result = _.reject(result,(text)->
            text[0] is "動画"
          )
          result = _.reject(result,(text)->
            text[0] is "画像"
          )
          for parts in result
            # Noun
            if parts[1] is '名詞' and parts[2] is '一般'
              if res = _.findWhere(dict,
                "part":"noun"
                "text":parts[0]
              )
                res.value += 1
              # init noun
              dict.push(
                "text":parts[0]
                "part":"noun"
                "value":1
              )
            # Adjactive
            if parts[1] is '形容詞'
              # init adj
              dict.push(
                "text":parts[0]
                "part":"adj"
                "value":1
              )
          console.log "::::::::::::::::::::::::::"
          # sort dict
          # now value >= 3
          dict = _.reject(dict,(word) ->
            word.value < 3
          )
          for word in dict
            socket.json.emit("send node",word)
            socket.json.emit("add link",
              json =
                "tempSource":origin.text
                "tempTarget":word.text
            )
            if hop < 3
              socket.emit("debug","debug")
              getListByGoogle(socket,word.text,hop)
        )
      catch e
        console.log e
    )
  ).on('error',(e) ->
    console.log e
  )

io = require('socket.io').listen(server)

io.sockets.on('connection',(socket) ->
  console.log "connect"

  socket.on('word',(word)->
    getListByGoogle(socket,word,1)
  )

  socket.on('disconnect',() ->
    console.log "disconnect"
  )
)
