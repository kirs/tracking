//=require Replay/replay_map
//=require Replay/choice_teams
//=require Replay/choice_editions
//=require Replay/choice_robots
//=require Replay/choice_onerobot
//=require Replay/handle_markers_replay
//=require Replay/choice_options

/*====================official markers=====================*/
//=require Replay/choice_display_official_markers
//=require Replay/officialMarkers


//need to check, when we did not change the option, but click the button update, it will display the initial page of google map and then reload the desired page

//need to check if we need to remeber choosing missions and attempts
//need to check if we need a ajax request for displaying a infowindow

//need to check chose start and end time to display all coordiantes
$(document).ready(function(){
	//initialization
	google.maps.event.addDomListener(window, 'load', initializeMap());
	//initializeMap();
	initialScroll();
	wantInfo();
	wantDoReplay();
  	displayMarkersOrnot();
  	requestRefreshTeams();
});


//-----------------------------------------------------------------
	
	function requestRefreshTeams(){
		/*=========================Begin choose teams and robots================================*/
		//choose teams <= choose robots <= choose mission <= choose attemps
		$.ajax({
			type: "GET",
			url: "/choice_teams",
			success: function(){
				run_choice_teams();
			}       
		});
	}

	/*===================End Choose teams and robots============================*/
