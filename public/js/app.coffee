define [
	'angular',
	'lodash',
	'restangular',
	'cs!./controllers/devices_controller',
	'cs!./controllers/download_controller',
	'cs!./controllers/work_controller',
	'cs!./controllers/login_controller',
	'cs!./helpers/create_poll',
	'cs!./helpers/auth',
	'reCAPTCHA',
	'angular-route',
	'angular-timeago',
	'ng-file-upload',
	'pubnub-angular',
	'bootstrap',
	'angular-bootstrap',
	'angular-google-analytics'
],
(angular, _, Restangular, devicesController, downloadController,
workController, loginController, createPoll, Auth) ->

	try
		angular.module('templateCache')
	catch
		angular.module('templateCache', [])

	angular
		.module('app', [
			'restangular',
			'ngRoute',
			'createPoll',
			'Auth',
			'yaru22.angular-timeago',
			'ngFileUpload',
			'pubnub.angular.service',
			'templateCache',
			'ui.bootstrap',
			'angular-google-analytics'
		])

		.value 'config',
			s3url: 'http://parallellocalypse.s3-website-us-east-1.amazonaws.com/'

		.run([ '$rootScope', 'Restangular' , 'PubNub', 'Auth', '$location', 'Analytics',
		($rootScope, Restangular, PubNub, Auth, $location, Analytics) ->
			PubNub.init
				subscribe_key: 'sub-c-1faf9860-f5c0-11e4-b21e-02ee2ddab7fe'

			Restangular.setErrorInterceptor (response) ->
				if response.status == 401
					Auth.logout()
					return false
				return true

			$rootScope.logout = Auth.logout
			$rootScope.isActive = (view) ->
				return $location.path().split('/')[1] == view
		])
		.config [ '$routeProvider', ($routeProvider) ->
			$routeProvider
				.when '/login',
					controller: loginController
					templateUrl: '/js/views/login.tpl'
				.when '/dashboard',
					controller: workController
					templateUrl: '/js/views/work.tpl'
				.when '/contact',
					controller: downloadController
					templateUrl: '/js/views/contact.tpl'
				.when '/faq',
					controller: downloadController
					templateUrl: '/js/views/faq.tpl'
				.when '/install',
					controller: downloadController
					templateUrl: '/js/views/landing.tpl'
				.when '/download',
					controller: downloadController
					templateUrl: '/js/views/landing.tpl'
				.when '/',
					controller: downloadController
					templateUrl: '/js/views/landing.tpl'
				.when '/devices',
					controller: devicesController
					templateUrl: '/js/views/devices.tpl'
				.when '/devices/:mac',
					controller: devicesController
					templateUrl: '/js/views/devices.tpl'
				.otherwise
					templateUrl: '/js/views/404.tpl'

		]
		.config [ 'RestangularProvider', (RestangularProvider) ->
			RestangularProvider.setBaseUrl('api')
		]
		.config [ 'AnalyticsProvider', (AnalyticsProvider) ->
			AnalyticsProvider.setAccount('UA-63317104-1');
			AnalyticsProvider.trackPages(true);
			AnalyticsProvider.useAnalytics(true);
		]
