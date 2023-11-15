var phone_max_width = 667;
var tablet_max_width = 1024;

var useIDX = true;
var useGLO = true;
var useFilter = true;

(function() {
	
	var rh = window.rh;
	
	//The side of the sidebar / mobile overlay
	rh.consts("SIDEBAR_STATE", ".e.sidebarstate");
	rh.model.publish(rh.consts("SIDEBAR_STATE"), false);
	
	//Number of search results to be loaded at once.
	rh.consts('MAX_RESULTS', '.l.maxResults');
	rh.model.publish(rh.consts('MAX_RESULTS'), 15);
	
	/* This layout has search on every page */
	rh.model.publish(rh.consts("KEY_CAN_HANDLE_SEARCH"), true);
	
	//Set the media queries
	var desktop = 'screen and (min-width: '+ (tablet_max_width + 1) +'px)';
	var tablet = 'screen and (min-width: '+ (phone_max_width + 1) +'px) and (max-width: '+ tablet_max_width +'px)';
	var phone = 'screen and (max-width: '+ phone_max_width +'px)';
	var screens = {
	  desktop: { media_query: desktop },
	  tablet: { media_query: tablet },
	  phone: { media_query: phone },
	  ios: {user_agent: /(iPad|iPhone|iPod)/g}
	};
	rh.model.publish(rh.consts('KEY_SCREEN'), screens);
	
	if(useIDX == false) {
		var idx = document.getElementById('idx-toggle-button');
		idx.parentNode.removeChild(idx);
	}
	if(useGLO == false) {
		var glo = document.getElementById('glo-toggle-button');
		glo.parentNode.removeChild(glo);
	}
	if(useFilter == false) {
		var filter = document.getElementById('filter-toggle-button');
		filter.parentNode.removeChild(filter);
	}
	
	//JavaScript handler.
	rh.MinimalistSetSidebar = function() {
		var sideBarToSet = rh.model.get(rh.consts('SIDEBAR_STATE'));
		
		var body = document.getElementsByTagName("body")[0];
		var toc = document.getElementById("toc-holder");
		var idx = document.getElementById("idx-holder");
		var glo = document.getElementById("glo-holder");
		var fts = document.getElementById("fts-holder");
		var filter = document.getElementById("filter-holder");
		var mobileMenu = document.getElementById("mobile-menu-holder");
		
		var visibleClass = "layout-visible";
		
		var setVisible = function(elem) {
			if(typeof(elem) != "undefined" && elem != null) {
				elem.classList.add(visibleClass);
			}
		}
		var setHidden = function(elem) {
			if(typeof(elem) != "undefined" && elem != null) {
				elem.classList.remove(visibleClass);
			}
		}
		
		var menuDelay = "has-delay";
		var menuImmediate = "no-transform";
		
		var showOtherMenu = function() {
			mobileMenu.classList.add(menuDelay);
			
			setTimeout(function(){
				mobileMenu.classList.remove(menuDelay);
				mobileMenu.classList.add(menuImmediate);
			},750);
		}
		
		var hideOtherMenu = function() {
			setTimeout(function(){
				mobileMenu.classList.remove(menuImmediate);
			}, 750);
		}
		
		body.classList.add("popup-visible");		
		
		switch(sideBarToSet) {
			case "toc":
				showOtherMenu();
				setVisible(toc);
				setHidden(idx);
				setHidden(glo);
				setHidden(fts);
				setHidden(filter);
				setHidden(mobileMenu);
				break;
			case "idx":
				showOtherMenu();
				setVisible(idx);
				setHidden(toc);
				setHidden(glo);
				setHidden(fts);
				setHidden(filter);
				setHidden(mobileMenu);
				break;
			case "glo":
				showOtherMenu();
				setVisible(glo);
				setHidden(idx);
				setHidden(toc);
				setHidden(fts);
				setHidden(filter);
				setHidden(mobileMenu);
				break;
			case "fts":
				showOtherMenu();
				setVisible(fts);
				setHidden(idx);
				setHidden(glo);
				setHidden(toc);
				setHidden(filter);
				setHidden(mobileMenu);
				break;
			case "filter":
				showOtherMenu();
				setVisible(filter);
				setHidden(idx);
				setHidden(glo);
				setHidden(fts);
				setHidden(toc);
				setHidden(mobileMenu);
				break;
			case "menu":
				setVisible(mobileMenu);
				hideOtherMenu();
				setHidden(idx);
				setHidden(glo);
				setHidden(fts);
				setHidden(toc);
				setHidden(filter);
				break;
			default: //Nothing. Show topic
				setHidden(idx);
				setHidden(glo);
				setHidden(fts);
				setHidden(toc);
				setHidden(filter);
				setHidden(mobileMenu);
				hideOtherMenu();
				body.classList.remove("popup-visible");
		}
	}
	rh.MinimalistSetSidebarSearch = function() {
		rh.model.publish(rh.consts("SIDEBAR_STATE"), "fts");
	}
	rh.MinimalistSetTransitionAllow = function() {
		var body = document.getElementsByTagName("body")[0];
		
		var allowPhone = "allow-phone-transitions";
		var allowTablet = "allow-tablet-transitions";
		var allowDesktop = "allow-desktop-transitions";
		
		body.classList.remove(allowPhone);
		body.classList.remove(allowTablet);
		body.classList.remove(allowDesktop);
		
		var toSet = false;
		if(rh.model.get(rh.consts('KEY_SCREEN_PHONE')) == true) {
			toSet = allowPhone;
		} else if(rh.model.get(rh.consts('KEY_SCREEN_TABLET')) == true) {
			toSet = allowTablet;
		} else if(rh.model.get(rh.consts('KEY_SCREEN_DESKTOP')) == true) {
			toSet = allowDesktop;
		}
		
		setTimeout(function(){
			
			body.classList.remove(allowPhone);//Always make sure there is only 1
			body.classList.remove(allowTablet);
			body.classList.remove(allowDesktop);
			
			body.classList.add(toSet);
		
		}, 10);
		
	}
	rh.model.subscribe(rh.consts("SIDEBAR_STATE"), rh.MinimalistSetSidebar);
	rh.model.subscribe(rh.consts("EVT_SEARCH_IN_PROGRESS"), rh.MinimalistSetSidebarSearch);
	rh.model.subscribe(rh.consts('KEY_SCREEN'), rh.MinimalistSetTransitionAllow);
	
	//For Keyboard accessibility, get the ESC key to close overlays
	document.onkeydown = function(evt) {
		evt = evt || window.event;
		if (evt.keyCode == 27) {
			rh.model.publish(rh.consts('SIDEBAR_STATE'), false);
		}
	};
	
}.call(this));