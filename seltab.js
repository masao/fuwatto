function seltab(bpref, hpref, id_max, selected) {
  if (! document.getElementById) return;
  for (i = 0; i <= id_max; i++) {
    if (! document.getElementById(bpref + i)) continue;
    if (i == selected) {
      document.getElementById(bpref + i).style.visibility = "visible";
      document.getElementById(bpref + i).style.position = "";
      document.getElementById(hpref + i).className = "open";
    } else {
      document.getElementById(bpref + i).style.visibility = "hidden";
      document.getElementById(bpref + i).style.position = "absolute";
      document.getElementById(hpref + i).className = "close";
    }
  }
}
