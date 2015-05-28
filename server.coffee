fs = require('fs')
path = require('path')

mongoose = require('mongoose')
express = require('express')
bodyParser = require('body-parser')
resin = require('resin-sdk')
config = require('./config')
passport = require('passport')
LocalStrategy = require('passport-local').Strategy
bcrypt = require('bcrypt-nodejs')
session = require('express-session')

mongooseURL = process.env.MONGOLAB_URI or process.env.MONGOHQ_URL or 'mongodb://localhost/parallellocalypse'
mongoose.connect mongooseURL, (err) ->
	if err
		throw err
	console.log('Connected to MongoDB')

mongoose.plugin(require('mongoose-paginate'))

token = config.token

resin.auth.loginWithToken token, (err) ->
	throw err if err?
	console.log('Authenticated with Resin')

port = process.env.PORT or 8080

passport.serializeUser (user, done) ->
	done(null, user)

passport.deserializeUser (user, done) ->
	done(null, user)

passport.use 'admin', new LocalStrategy({
	usernameField: 'email',
	passwordField: 'password',
	passReqToCallback: true
}, (req, email, password, done) ->
	if email != config.admin.email or password != config.admin.password
		return done(null, false)

	user = {
		type: 'admin'
		email
	}

	return done(null, user)

)

passport.use 'device', new LocalStrategy({
	usernameField: 'macAddress',
	passwordField: 'secret',
	passReqToCallback: true
}, (req, macAddress, secret, done) ->

	if !bcrypt.compareSync(macAddress + config.device.secret, secret)
		return done(null, false)

	user = {
		type: 'device'
	}

	return done(null, user)

)

app = express()
app.use(bodyParser())

app.use (req, res, next) ->
	console.log('%s %s', req.method, req.url)
	next()

if process.env.NODE_ENV == 'production'
	app.use(express.static(__dirname + '/build'))
else
	swig = require('swig')
	viewsDir = __dirname + '/views'
	app.engine('swig', swig.renderFile)
	app.set('view engine', 'swig')
	app.set('views', viewsDir)
	pages = fs.readdirSync("#{viewsDir}/pages").map (fileName) ->
		path.basename(fileName, '.swig')
	pages.forEach (page) ->
		app.get "/#{page}.html", (req, res) ->
			res.render("pages/#{page}")
	app.get '/', (req, res) ->
		res.render('pages/index')

	app.use(express.static(__dirname + '/public'))


app.use(session({ secret: 'themostamazingsupercomputer' }))
app.use(passport.initialize())
app.use(passport.session())

app.use('/', require('./controllers/auth_controller').router(passport))

app.use('/api/', require('./controllers/devices_controller')(passport))
app.use('/api/', require('./controllers/download_controller'))
app.use('/api/', require('./controllers/work_controller'))
app.use('/api/', require('./controllers/images_controller'))

app.get '/api/subscribe_key', (req, res) ->
	res.send(config.subscribe_key)

app.listen port, ->
	console.log("Server listening on port #{port}")
