function scrolldown_frame(selector) {
    var contents = $(selector).contents();
    contents.scrollTop(contents.height());
}

function setheight_frame(selector) {
    var offsety = $(selector).offset().top;
    var footerheight = 100;
    var newheight = ( $(window).height() - offsety - footerheight );
    if ( newheight > 200 ){
        $(selector).attr(
            "style",
            "height:" + newheight + "px"
        );
    }
}

function setsrc_frame(selector) {
    var src = $(selector).attr("src");
    $(selector).attr(
        "src",
        src
    );
}

function all_frames_scrolldown() {
    scrolldown_frame('#frame1');
    scrolldown_frame('#frame2');
}
function all_frames_setheight() {
    setheight_frame('#frame1');
    setheight_frame('#frame2');
}
function all_frames_configure() {
    all_frames_scrolldown();
    all_frames_setheight();
}

var global_timer;

function all_frames_setsrc(ms) {
    setsrc_frame('#frame1');
    setsrc_frame('#frame2');
    setTimeout(function(){ all_frames_scrolldown(); }, 1000);
    global_timer = setTimeout(function(){ all_frames_setsrc(ms); }, ms);
}
function timer_reload_frames(){
    var hours = 1;
    var minutes = hours * 60;
    var seconds = minutes * 60;
    var ms = seconds * 1000;
    global_timer = setTimeout(function(){ all_frames_setsrc(ms); }, ms);
}

$(document).ready(function () {
    all_frames_configure();
    timer_reload_frames();
});
$(window).on('load', function(){
    all_frames_configure();
    timer_reload_frames();
});

$(window).on('resize', function(){
    all_frames_setheight();
});
