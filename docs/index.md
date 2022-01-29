---
layout: fairapp
title: The App Fair
appname: App-Fair
appurl: "https://github.com/App-Fair/App"
showicon: false
---

<style>
header {
  display: none;
}

XXXbody {
    background: #000000FF;
    color: white;
}

XXXhr {
    color: #AAAAAA;
}

XXXa, XXXa:visited {
    color: green;
}

XXXa:hover {
    color: red;
}

XXXcode {
    background: #333333;
}

</style>

<!--
Launch Link (required): https://appfair.app/fair#app/App-Fair
-->

{% assign apptitle = page.appname | replace: "-", " " %}

<div>
<a style="text-decoration: none;" href="{{ page.appurl }}/releases/latest/download/{{ page.appname }}-macOS.zip">
<button style="margin-left: auto; margin-right: auto; text-align: center; user-select: none; background-color: #2171A1; color: #FFFFFF; border: none; padding: 12px 12px; text-decoration: none; display: inline-block; cursor: pointer; border-radius: 15px; user-select: none; display: flex; flex-direction: row;">
    <div style="margin-top: auto; margin-bottom: auto;">
    <svg width="44px" height="44px" viewBox="0 0 44 44" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
        <g stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
            <g fill="#FFFFFF" fill-rule="nonzero">
                    <path d="M21.9895883,44 C25.0159331,44 27.8548667,43.4289759 30.506389,42.2869278 C33.1579113,41.1448797 35.493611,39.5598553 37.5134879,37.5318546 C39.5333649,35.503854 41.1194195,33.1643857 42.2716517,30.5134497 C43.4238839,27.8625138 44,25.0281579 44,22.0103823 C44,18.9787636 43.4238839,16.1374862 42.2716517,13.4865503 C41.1194195,10.8356143 39.5333649,8.49614598 37.5134879,6.46814535 C35.493611,4.44014472 33.1544408,2.85512034 30.4959773,1.7130722 C27.8375138,0.571024068 25.0020508,0 21.9895883,0 C18.9771257,0 16.1416627,0.571024068 13.4831992,1.7130722 C10.8247358,2.85512034 8.48556555,4.44014472 6.46568859,6.46814535 C4.44581164,8.49614598 2.86322764,10.8356143 1.71793658,13.4865503 C0.572645528,16.1374862 0,18.9787636 0,22.0103823 C0,25.0281579 0.572645528,27.8625138 1.71793658,30.5134497 C2.86322764,33.1643857 4.44928222,35.503854 6.47610033,37.5318546 C8.50291844,39.5598553 10.8420887,41.1448797 13.493611,42.2869278 C16.1451333,43.4289759 18.9771257,44 21.9895883,44 Z M22.0104117,28.0943841 C21.7188831,28.0943841 21.4447074,28.0355514 21.1878845,27.9178858 C20.9310617,27.8002202 20.7124152,27.6514079 20.5319451,27.4714488 L13.5977283,20.7437471 C13.3894936,20.5499449 13.2333176,20.3215353 13.1292002,20.0585182 C13.0250828,19.795501 12.9730241,19.5532484 12.9730241,19.3317603 C12.9730241,18.7226679 13.1500237,18.2347019 13.5040227,17.8678622 C13.8580218,17.5010225 14.3126676,17.3176026 14.8679602,17.3176026 C15.1733712,17.3176026 15.4406058,17.3764354 15.669664,17.494101 C15.8987222,17.6117666 16.1034864,17.7744219 16.2839565,17.982067 L17.6166588,19.3317603 L20.2612399,22.2180274 L19.9905348,19.0410571 L19.9905348,11.8773006 C19.9905348,11.2405223 20.1744755,10.7248702 20.5423568,10.3303445 C20.9102382,9.93581878 21.3995898,9.73855592 22.0104117,9.73855592 C22.5795867,9.73855592 23.0481148,9.93581878 23.4159962,10.3303445 C23.7838776,10.7248702 23.9678183,11.2405223 23.9678183,11.8773006 L23.9678183,19.0410571 L23.7387601,22.2180274 L26.3416943,19.3317603 L27.7160435,17.982067 C27.910396,17.7882649 28.1290424,17.6290703 28.371983,17.5044832 C28.6149235,17.3798962 28.8821581,17.3176026 29.1736867,17.3176026 C29.715097,17.3176026 30.1628017,17.507944 30.5168008,17.8886267 C30.8707998,18.2693094 31.0477993,18.7434324 31.0477993,19.3109958 C31.0477993,19.5740129 30.9992112,19.8301085 30.902035,20.0792827 C30.8048588,20.3284568 30.6452122,20.5499449 30.4230951,20.7437471 L23.4680549,27.4714488 C23.2875848,27.6514079 23.0689383,27.8002202 22.8121155,27.9178858 C22.5552926,28.0355514 22.2880581,28.0943841 22.0104117,28.0943841 Z M14.3681969,33.2647475 C13.8267866,33.2647475 13.3721407,33.0744062 13.0042593,32.6937235 C12.636378,32.3130407 12.4524373,31.8458392 12.4524373,31.2921189 C12.4524373,30.7383986 12.636378,30.2746579 13.0042593,29.9008966 C13.3721407,29.5271354 13.8267866,29.3402548 14.3681969,29.3402548 L29.6526266,29.3402548 C30.1940369,29.3402548 30.6452122,29.5271354 31.0061524,29.9008966 C31.3670926,30.2746579 31.5475627,30.7383986 31.5475627,31.2921189 C31.5475627,31.8458392 31.3670926,32.3130407 31.0061524,32.6937235 C30.6452122,33.0744062 30.1940369,33.2647475 29.6526266,33.2647475 L14.3681969,33.2647475 Z" id="Shape"></path>
            </g>
        </g>
    </svg>
    </div>
    <div style="padding-left: 16px; padding-right: 16px;">
        <span style="font-size: 30px; color: #FFFFFF; font-weight: bold; font-family: ui-rounded, Arial Rounded MT Bold, system-ui, HelveticaNeue, Helvetica Neue;">Download {{ apptitle }}.app</span>
        <br />
        <span style="text-align: right; font-size: 16px; color: #FAFAFA; font-family: system-ui, Arial MT, HelveticaNeue, Helvetica Neue;">3.5MB – requires macOS 12+</span>
    </div>
</button>
</a>
</div>   
<br />
<br />

<img style="width: 50%;" align="right" src="screenshots/screenshot_01-mac-2484x1742.png" />

Browse, download and install Mac apps from a vast catalog of both free and commercial native desktop applications. The App Fair enables the discovery of third-party applications from the community homebrew [casks](https://formulae.brew.sh/cask/) catalog, as well as accessing free and open-source apps published through the [appfair.net](https://appfair.net) distribution platform.

{% assign browsers = '
<a href="https://appfair.app/fair#cask/microsoft-edge">Edge</a>;
<a href="https://appfair.app/fair#cask/firefox">Firefox</a>;
<a href="https://appfair.app/fair#cask/google-chrome">Chrome</a>
' | strip | split: ";" | sample: 3 %}

{% assign messengers = '
<a href="https://appfair.app/fair#cask/signal">Signal</a>;
<a href="https://appfair.app/fair#cask/zoom">Zoom</a>;
<a href="https://appfair.app/fair#cask/discord">Discord</a>
' | strip | split: ";" | sample: 3 %}

{% assign players = '
<a href="https://appfair.app/fair#cask/spotify">Spotify</a>;
<a href="https://appfair.app/fair#cask/tidal">TIDAL</a>;
<a href="https://appfair.app/fair#cask/vlc">VLC</a>
' | strip | split: ";" | sample: 3 %}

{% assign tools = '
<a href="https://appfair.app/fair#cask/visual-studio-code">VS Code</a>;
<a href="https://appfair.app/fair#cask/dropbox">Dropbox</a>;
<a href="https://appfair.app/fair#cask/docker">Docker</a>
' | strip | split: ";" | sample: 3 %}

{% assign design = '
<a href="https://appfair.app/fair#cask/sketch">Sketch</a>;
' | strip | split: ";" | sample: 3 %}

{% assign games = '
<a href="https://appfair.app/fair#cask/minecraft">Minecraft</a>;
<a href="https://appfair.app/fair#cask/steam">Steam</a>;
' | strip | split: ";" | sample: 3 %}


From world-class web browsers like {{ browsers[0] }}, {{ browsers[1] }}, and {{ browsers[2] }}, to essential messaging apps like {{ messengers[0] }}, {{ messengers[1] }}, and {{ messengers[2] }}, and from media players like {{ players[0] }}, {{ players[1] }}, and {{ players[2] }} to critical tech tools like {{ tools[0] }}, {{ tools[1] }}, and {{ tools[2] }}, the App Fair is your missing source for all the Mac apps that you need and use every day. 

## Straight from the Makers

The apps you acquire through the App Fair come straight from their creators, with no intermediaries. They are granted the full protection of macOS's built-in security features like MRT & XProtect, while at the same time remaining unconstrained by many of the restrictions that can hobble apps installed through other channels. 

<!-- App Fair.app has access to catalogs from:

  * [brew.sh](https://brew.sh): Homebrew is the “Missing Package Manager for macOS”
  * [appfair.net](https://appfair.net): -->

## Enter the App Fair

Download <a style="text-decoration: none;" href="{{ page.appurl }}/releases/latest/download/{{ page.appname }}-macOS.zip">App Fair.app</a> for macOS Monterey now. For existing homebrew users, it can also be installed and launched by running the following command from Terminal.app:

<pre>
$ brew install appfair/app/app-fair && open /Applications/'App Fair.app'
</pre>

<br />
<br />
<br />


<!-- 
<img style="width: 50%;" align="left" src="screenshots/screenshot_03-mac-dark-2878x2120.png" />
<h4>About the App Fair</h4>

<br />
<br />
<br />
<br />
<br />
<br />
<br />
<br />
<br />
<br />
<br />
<br /> 
-->

<hr />

<center>Screenshots</center>
