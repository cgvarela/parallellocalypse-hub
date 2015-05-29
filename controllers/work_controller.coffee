express = require('express')
router = express.Router()
resin = require('resin-sdk')
fs = require('fs')
config = require('../config')
multer = require('multer')

Device = require('../models/device')
Workload = require('../models/workload')
dispatcher = require '../models/dispatcher'
Image = require('../models/image')

auth = require('./auth_controller')

router.use(multer({}))

router.all '/warmup', auth.isLoggedIn, (req, res, next) ->
	dispatcher.warmCache()
	res.send('OK')

router.post '/work/stop', (req, res) ->
	if !dispatcher.idle
		dispatcher.stop()
	res.send({})

router.post '/work', auth.isLoggedIn, (req, res, next) ->
	if dispatcher.idle
		workload = new Workload({
			status: 'Starting',
			numAssigned: 0,
			assigned: []
		})
		image = new Image({personName: null, target: true })

		image.attach 'image', req.files.image, (err) ->
			if(err)
				return next(err)

			image.save (err) ->
				if(err)
					return next(err)

				workload.targetImage = image
				workload.save (err) ->
					dispatcher.start workload
					res.send(workload)
	else
		res.send({error: 'Dispatcher is busy'})

router.get '/work', auth.isLoggedIn, (req, res, next) ->
	Workload.find({}).populate('targetImage').exec (err, workloads) ->
		res.send(workloads)

# This one's public
router.get '/work/current', (req, res) ->
	res.send(dispatcher.workload)

router.get '/work/:id', auth.isLoggedIn, (req, res) ->
	Workload.findOne({_id: req.params.id}).populate('targetImage').exec (err, workload) ->
		res.send(workload)

module.exports = router
