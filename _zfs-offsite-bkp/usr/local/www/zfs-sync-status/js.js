var global_timer;

// Log files
var count_frames = 6;

function scrolldown_frame(selector) {
    var contents = $(selector).contents();
    contents.scrollTop(contents.height());
}
function setsrc_frame(selector) {
    var src = $(selector).attr("src");
    $(selector).attr(
        "src",
        src
    );
}
function all_frames_scrolldown() {
    for (var i=0; i<count_frames; i++) {
        scrolldown_frame('#frame'+(i+1));
    }
}
function all_frames_configure() {
    all_frames_scrolldown();
}
function timer_reload_frames() {
    var hours = 1;
    var minutes = hours * 60;
    var seconds = minutes * 60;
    var ms = seconds * 1000;
    for (var i=0; i<count_frames; i++) {
        setsrc_frame('#frame'+(i+1));
    }
    setTimeout(function(){ all_frames_scrolldown(); }, 1000);
    global_timer = setTimeout(function(){ timer_reload_frames(); }, ms);
}
function add_coloricontxt(datasets) {
    $("#coloricontxt").empty();
    for (var i=0; i<datasets.length; i++) {
        var newdiv = $("<div>");
        newdiv.attr("id","zfsdataset"+(i+1));
        $("#coloricontxt").append(newdiv);
    }
    default_all_coloricontxt(datasets);
}
function set_coloricontxt(selector,color,icon,txt,subtxt) {
    var col = $("<div>");
    col.attr("class","col-lg-3 col-md-6");

    var panel = $("<div>");
    panel.attr("class","panel panel-" + color);

    var footer = $("<div>");
    footer.attr("class","panel-footer");

    var details = $("<div>");
    details.attr("class","pull-right text-right");
    details.html(subtxt);

    var clrfix = $("<div>");
    clrfix.attr("class","clearfix");

    var heading = $("<div>");
    heading.attr("class","panel-heading");

    var row = $("<div>");
    row.attr("class","row");

    var colico = $("<div>");
    colico.attr("class","col-xs-3");

    var ico = $("<i>");
    ico.attr("class","fa fa-"+ icon +" fa-2x");
    $(colico).empty().append(ico);

    var coltxt = $("<div>");
    coltxt.attr("class","col-xs-9 text-right");

    var divtxt = $("<div>");
    divtxt.text(txt);
    $(coltxt).empty().append(divtxt);

    $(row).empty().append(colico).append(coltxt);
    $(heading).empty().append(row);
    $(footer).empty().append(details).append(clrfix);
    $(panel).empty().append(heading).append(footer);
    $(col).empty().append(panel);
    $(selector).empty().append(col);
}
function default_all_coloricontxt(datasets) {
    for (var i=0; i<datasets.length; i++) {
        set_coloricontxt('#zfsdataset'+(i+1), "yellow", "question", datasets[i].name, "loading...");
    }
}
function test_all_coloricontxt(datasets) {
    var colors = ["green", "yellow", "red"];
    var icons = ["check", "question", "times"];
    for (var i=0; i<datasets.length; i++) {
        var color_i = i;
        for ( ; color_i >= colors.length; color_i-=colors.length ){
            //nop
        }
        var icon_i = i;
        for ( ; icon_i >= icons.length; icon_i-=icons.length ){
            //nop
        }
        set_coloricontxt('#zfsdataset'+(i+1), colors[color_i], icons[icon_i], datasets[i].name, "testing");
    }
}
function parse_coloricontxt_dataset(datasets) {
    var color = "yellow";
    var icon = "question";
    for (var i=0; i<datasets.length; i++) {
        if ( datasets[i].local == datasets[i].remote ) {
            color = "green";
            icon = "check";
        } else {
            color = "red";
            icon = "times";
        }
        set_coloricontxt('#zfsdataset'+(i+1), color, icon, datasets[i].name, "local:"+datasets[i].local+"<br/>remote:"+datasets[i].remote);
    }
}
function fetch_datasets() {
    $.ajax({
        url: "./json-datasets.js",
        dataType: "json"
    }).success(function(data) {
        add_coloricontxt(data);
        //test_all_coloricontxt(data);
        //parse_coloricontxt_dataset(data);
    });
}
function fetch_snapshots() {
    $.ajax({
        url: "./json-snapshots.js",
        dataType: "json"
    }).success(function(data) {
        parse_coloricontxt_dataset(data);
    });
}
function timer_fetch_snapshots() {
    var hours = 1;
    var minutes = hours * 60;
    var seconds = minutes * 60;
    var ms = seconds * 1000;
    fetch_snapshots();
    global_timer = setTimeout(function(){ timer_fetch_snapshots(); }, ms);
}
function parse_space(selector,data) {
    var plotObj = $.plot($(selector), data, {
        series: {
            pie: {
                show: true
            }
        },
        grid: {
            hoverable: true
        },
        tooltip: true,
        tooltipOpts: {
            content: "%p.0%, %s", // show percentages, rounding to 2 decimal places
            shifts: {
                x: 20,
                y: 0
            },
            defaultTheme: false
        }
    });
}
function fetch_ramusage() {
    $.ajax({
        url: "./json-ramusage.js",
        dataType: "json"
    }).success(function(data) {
        parse_space("#flot-pie-chart1",data);
    });
}
function fetch_poolspace() {
    $.ajax({
        url: "./json-poolspace.js",
        dataType: "json"
    }).success(function(data) {
        parse_space("#flot-pie-chart2",data);
    });
}
function fetch_tankspace() {
    $.ajax({
        url: "./json-tankspace.js",
        dataType: "json"
    }).success(function(data) {
        parse_space("#flot-pie-chart3",data);
    });
}

function doc_load() {
    all_frames_configure();
    timer_reload_frames();
    fetch_datasets();
    timer_fetch_snapshots();
    fetch_ramusage();
    fetch_poolspace();
    fetch_tankspace();
}
$(document).ready(function(){ doc_load(); });
//$(window).on('load', function(){ doc_load(); });
