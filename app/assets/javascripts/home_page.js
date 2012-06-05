var HomePage = {
	init: function(showFlash){
		this.slider();
		this.resetStatus();
		this.displayComplimentForm(showFlash);
		$('#learn-more').fancybox();
	},
	slider: function() {
		$('#slider').cycle({
			fx: 'fade',
			timeout: 0,
			pause: true,
			next: '#slider-state-1',
			prev: '#slider-state-2',
			before: HomePage.resetStatus()
		});
	},
	resetStatus: function() {
		// On initial load, neither of them will have slider-active
		var initialState = !$('#slider-state-1').hasClass("slider-active") &&
		 									 !$('#slider-state-2').hasClass("slider-active");
		// If state 1 is active, flip to state 2
		var state1Active = $('#slider-state-1').hasClass("slider-active");
		if(initialState) {
			HomePage.employeeSlideIsVisible();				
		} else if(state1Active) {
			HomePage.employerSlideIsVisible();
		} else {
			HomePage.employeeSlideIsVisible();
		}
	},
	employeeSlideIsVisible: function() {
		$('#slider-state-1').addClass("slider-active");
		$('#slider-state-1').removeClass("slider-inactive");
		$('#slider-state-2').addClass("slider-inactive");
		$('#slider-state-2').removeClass("slider-active");
	},
	employerSlideIsVisible: function() {
		$('#slider-state-1').addClass("slider-inactive");
		$('#slider-state-1').removeClass("slider-active");
		$('#slider-state-2').addClass("slider-active");
		$('#slider-state-2').removeClass("slider-inactive");
	},
	displayComplimentForm: function(showFlash) {
		$('#main-page-receiver-email-label').html('');
		if(showFlash) {
			HomePage.showComplimentFormNoSlide();
		} else {
			setTimeout(HomePage.showComplimentForm, 10000);
			$('#compliment_receiver_email').click(function() {
				HomePage.showComplimentForm();
			}).focus(function() {
				HomePage.showComplimentForm();
			});
		}
	},
	showComplimentForm: function() {
		var complimentForm = $('#compliment-form-slider');
		if( !complimentForm.is(":visible") ) {
			$('#main-page-receiver-email-label').html('*To');
			complimentForm.slideDown(700);
		}
	},
	showComplimentFormNoSlide: function() {
		var complimentForm = $('#compliment-form-slider');
		if( !complimentForm.is(":visible") ) {
			$('#main-page-receiver-email-label').html('*To');
			complimentForm.show();
		}
	}
}