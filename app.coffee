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

getListByYahoo = (socket,word,hop,next)->
  hop += 1
  origin =
    "text":word
    "value":5
    "part":"origin"
  console.log origin
  socket.json.emit("send node",origin)
  options =
    hostname: 'search.yahoo.co.jp'
    path: "/search?p=#{next}&aq=-1&oq=&ei=UTF-8&fr=top_ga1_sa&x=wrt&num=40"
  http.get(options,(res) ->
    console.log "status"+res.statusCode
    if res.statusCode is 302
      console.log res
    body =''
    res.on('data',(data)->
      body += data.toString()
    )
    res.on('end',() ->
      try
        $ = cheerio.load body
        src = $("a").text()
        ###
        $("a").each((i,elem)->
          console.log $("a")[i].attribs.href
        )
        ###
        src += $("#web").text()
        mecab.parse(src,(err,result)->
          #console.log result
          # for google
          ###
          result = _.reject(result,(text)->
            text[0] is "キャッシュ"
          )
          ###
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
          # console.log dict
          # sort dict
          dict = _.reject(dict,(word) ->
            word.value < hop
          )
          #console.log dict
          for word in dict
            console.log word
            socket.json.emit("send node",word)
            socket.json.emit("add link",
              json =
                "tempSource":origin.text
                "tempTarget":word.text
            )
            if hop < 3
              getListByYahoo(socket,word.text,hop,word.text+" "+origin.text)
        )
      catch e
        console.log e
    )
  ).on('error',(e) ->
    console.log e
  )
#getListByYahoo("socket","チェルシー",1)

io = require('socket.io').listen(server)

io.sockets.on('connection',(socket) ->
  console.log "connect"

  socket.on('word',(word)->
    getListByYahoo(socket,word,1,word)
  )

  socket.on('disconnect',() ->
    console.log "disconnect"
  )
)
