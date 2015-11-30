var global_timer;
var pies = [
    {
        name:"ram",
        text:"RAM Usage"
    },
    {
        name:"pool",
        text:"Operating System Disk Space"
    },
    {
        name:"tank",
        text:"Data Storage Disk Space"
    }
];
// Log files
var count_frames = 6;

function find_replace_tank_urep(str) {
    var res = str.replace("tank/urep/","");
    return res;
}
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
function add_coloricontxt_placeholder(datasets) {
    $("#coloricontxt").empty();
    for (var i=0; i<datasets.length; i++) {
        var newdiv = $("<div>");
        newdiv.attr("id","zfsdataset"+find_replace_tank_urep(datasets[i].name));
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

    var coltxt = $("<div>");
    coltxt.attr("class","col-xs-9 text-right");

    var hugetxt = $("<div>");
    hugetxt.attr("class","huge");
    hugetxt.text(subtxt.replace("local:","").replace(/-.*/,"").replace("loading...",""));

    var divtxt = $("<div>");
    divtxt.text(txt);

    $(colico).empty().append(ico);
    $(coltxt).empty().append(hugetxt).append(divtxt);
    $(row).empty().append(colico).append(coltxt);
    $(heading).empty().append(row);
    $(footer).empty().append(details).append(clrfix);
    $(panel).empty().append(heading).append(footer);
    $(col).empty().append(panel);
    $(selector).empty().append(col);
}
function default_all_coloricontxt(datasets) {
    for (var i=0; i<datasets.length; i++) {
        set_coloricontxt('#zfsdataset'+find_replace_tank_urep(datasets[i].name), "yellow", "question", find_replace_tank_urep(datasets[i].name), "loading...");
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
        set_coloricontxt('#zfsdataset'+find_replace_tank_urep(datasets[i].name), colors[color_i], icons[icon_i], find_replace_tank_urep(datasets[i].name), "testing");
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
        set_coloricontxt('#zfsdataset'+find_replace_tank_urep(datasets[i].name), color, icon, find_replace_tank_urep(datasets[i].name), "local:"+datasets[i].local+"<br/>remote:"+datasets[i].remote);
    }
}
function fetch_datasets() {
    $.ajax({
        url: "./json-datasets.js",
        dataType: "json"
    }).success(function(data) {
        add_coloricontxt_placeholder(data);
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
    fetch_ramusage();
    fetch_poolspace();
    fetch_poolstatus();
    fetch_tankspace();
    fetch_tankstatus();
    global_timer = setTimeout(function(){ timer_fetch_snapshots(); }, ms);
}
function labelFormatter(label, series) {
    return "<div style='text-align: center; font-size: 2em; font-weight: bold;'>" + label + "<br/>" + Math.round(series.percent) + "%</div>";
}
function parse_space(selector,data) {
    var plotObj = $.plot($(selector), data, {
        series: {
            pie: {
                show: true,
                radius: 1,
                label: {
                    show: true,
                    radius: 2/3,
                    formatter: labelFormatter,
                    threshold: 0.1
                }
            }
        },
        legend: {
            show: false
        },
        grid: {
            hoverable: false
        },
        tooltip: false
    });
}
function fetch_ramusage() {
    $.ajax({
        url: "./json-ramusage.js",
        dataType: "json"
    }).success(function(data) {
        parse_space("#flot-pie-chartram",data);
    });
}
function fetch_poolspace() {
    $.ajax({
        url: "./json-poolspace.js",
        dataType: "json"
    }).success(function(data) {
        parse_space("#flot-pie-chartpool",data);
    });
}
function fetch_tankspace() {
    $.ajax({
        url: "./json-tankspace.js",
        dataType: "json"
    }).success(function(data) {
        parse_space("#flot-pie-charttank",data);
    });
}
function fetch_poolstatus() {
    $.ajax({
        url: "./poolstatus.txt",
        dataType: "text"
    }).success(function(data) {
        $("#zpoolstatuspool").text(data);
    });
}
function fetch_tankstatus() {
    $.ajax({
        url: "./tankstatus.txt",
        dataType: "text"
    }).success(function(data) {
        $("#zpoolstatustank").text(data);
    });
}


function doc_load() {

    // setup placeholders
    fetch_datasets();

    // start timer to fetch logs
    timer_reload_frames();

    // start timer to fetch real data
    timer_fetch_snapshots();
}
$(document).ready(function(){ doc_load(); });
//$(window).on('load', function(){ doc_load(); });
