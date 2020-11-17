;;author: Gildas Assogba
__includes ["biomtransfer.nls" "market.nls" "message.nls"]

globals [
  season;;type of season: 0=bad, 1=good, 2=very good
  saison;; explanation of season, see set up
  month
  mois
  ngseason;;ngseason: grain units per season
  nrseason;; nrseason: residue units
  cultivplot;; cultivated plots
  bushplot;;bush
  farmers;;farms
  farmi;;list of farms
  graine
  resid
  mn;;event: manure creation on bushplot, happen once
  cc;;cattle creation for farm, happen once
  maxc maxr maxd maxp maxrc;;number of farm owing a certain type of animal
  canharvest;
  exchg;if one biomass exchange already occured, used in biomexchange
  warn;display warnings related to livestock
  ;feedfam;; control family feeding (grain)
  year
  forage;livestock feeding by farmer
  day;used in reproduce and nextmonth
  idplayer; list of players
  nj; index for players list
]

breed [joueurs joueur]
directed-link-breed [biom_owner a-biom_owner]
directed-link-breed [biom_transfer a-biom_transfer]

patches-own [
 residue;;crop residue
 grain;;grain produced on agricultural plots
 grass;; grass on bush plots only
 cultiv;; is the patch cultivated or not?y/n
 ferti;;fertilized plot?y/n
 manu;;manure applied to plot?y/n
 harvested;;is plot harvested? y/n
]

joueurs-own [
  pseudo; name the player use entering the game
  idplay;
  residue_on_field
  send_biomass
  send_to
  send_how_much
  buy_what
  who_buy
  amount_buy
  sell_what
  who_sell
  amount_sell
  biom_weight
  message_text
  message_who
]

turtles-own [
  pos
  nature
  typo
  nplot
  playerpos
  player
  farm
  family_size
  ncow
  ndonkey
  nsrum
  npoultry
  nfertilizer
  ncart
  ntricycle
  ngrain
  nresidue;residue harvested
  nresiduep;residue on plots
  nconc
  nmanure
  onfarm_inc
  offfarm_inc
  fertilized
  canmove; distinguish moving agent from fictive ones
  energy;;of livestock
  neat;;number of times a residue agent is grazed
  open;;residue available for grazing
  grazed;;animal already ate?
  state;of livestock skinny medium fat
  repro;if an animal already reproduce during one year, y/n
  food_unsecure;; number of person food unsecure in the HH
  feedfam
  hunger;increase if an animal did not eat in a step, see reproduce
  nf;see livupdate, for fertilizer
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;HUBNET;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to startup
  hubnet-reset
  set-up
  listen-clients
end

to listen-clients
  while [ hubnet-message-waiting? ] [
    hubnet-fetch-message
    ifelse hubnet-enter-message? [
      create-new-player
      ask joueurs [update]
    ] [
      ifelse hubnet-exit-message? [
        remove-player
      ] [
        ask joueurs with [ pseudo = hubnet-message-source ] [
          execute-command hubnet-message-tag
        ]
      ]
    ]
  ]
end

to create-new-player
  set idplayer (list "player 1" "player 2" "player 3" "player 4")
  ifelse nj < 4 [
  create-joueurs 1 [
    set pseudo hubnet-message-source
    set idplay item nj idplayer
    set hidden? true
      set residue_on_field 0
      set send_biomass "residue"
      set send_to "player 1"
      set send_how_much 0
      set buy_what "residue" set who_buy "player 1" set amount_buy 0
      set sell_what "residue" set who_sell "player 1" set amount_sell 0
      set biom_weight "skinny"
      ;set message_who "player 1"
  ]
    set nj nj + 1]
  [user-message "Maximum number of player reached"]
end

to remove-player
  ask joueurs with [pseudo = hubnet-message-source][die]
end

to go
  listen-clients
  ask joueurs [update]
end

to update
  let stck 0 let stck2 0 let rskc 0 let rsks 0 let rskd 0
  let idplays idplay
  hubnet-send pseudo "nplot" item 0[nplot] of farmers with [player = idplays]
  hubnet-send pseudo "cattle" item 0[ncow] of farmers with [player = idplays]
  hubnet-send pseudo "srum" item 0[nsrum] of farmers with [player = idplays]
  hubnet-send pseudo "donkey" item 0[ndonkey] of farmers with [player = idplays]
  hubnet-send pseudo "poultry" item 0[npoultry] of farmers with [player = idplays]
  hubnet-send pseudo "nplot" item 0[nplot] of farmers with [player = idplays]
  hubnet-send pseudo "fertilizer" item 0[nfertilizer] of farmers with [player = idplays]
  hubnet-send pseudo "tricycle" item 0[ntricycle] of farmers with [player = idplays]
  hubnet-send pseudo "cart" item 0[ncart] of farmers with [player = idplays]
  hubnet-send pseudo "grain" item 0[ngrain] of farmers with [player = idplays]
  hubnet-send pseudo "residue harv" item 0[nresidue] of farmers with [player = idplays]
  ask farmers with [player = idplays][
    set stck count out-link-neighbors with [typo = "residue" and hidden? = true and shape = "star"]
    set stck2 count out-link-neighbors with [typo = "residue" and hidden? = false and shape = "star"]
    set rskc count out-link-neighbors with [shape = "cow" and canmove = "yes" and hunger > 0]
    set rsks count out-link-neighbors with [shape = "sheep" and canmove = "yes" and hunger > 0]
    set rskd count out-link-neighbors with [shape = "wolf" and canmove = "yes" and hunger > 0]
  ]
  hubnet-send pseudo "stock residue" stck
  hubnet-send pseudo "residue on field" stck2
  hubnet-send pseudo "manure" item 0[nmanure] of farmers with [player = idplays]
  hubnet-send pseudo "conc" item 0[nconc] of farmers with [player = idplays]
  hubnet-send pseudo "manure" item 0[nmanure] of farmers with [player = idplays]
  hubnet-send pseudo "off farm" item 0[offfarm_inc] of farmers with [player = idplays]
  hubnet-send pseudo "on farm" item 0[onfarm_inc] of farmers with [player = idplays]
  hubnet-send pseudo "risky cow" rskc hubnet-send pseudo "risky srum" rsks hubnet-send pseudo "risky donkey" rskd
  hubnet-send pseudo "food unsecure" item 0[food_unsecure] of farmers with [player = idplays]
  hubnet-send pseudo "pseudo_" pseudo
  hubnet-send pseudo "name" idplay
end

to execute-command [command ]
  if command = "transfer_biomass" [biomtransfer]
  if command = "Market" [market]
  if command = "feed family" [feedfamily idplay livupdate idplay]
  if command = "send message" [message]
  if command != "transfer_biomass" and command != "Market"
  and command != "feed family" and command != "message"[
   receive-message
  ]
end


to set-up
  set nj 0
  set idplayer (list "player 1" "player 2" "player 3" "player 4")
  clear-all
  set season one-of (range 0 3 1)
  if season = 0 [set saison "Bad :("]
  if season = 1 [set saison "Good :)"]
  if season = 2 [set saison "Very good :)"]
  set mois (list "July" "August" "September" "October" "November" "December"
    "January" "February" "March" "April" "May" "June")
  set farmers turtles with [shape = "person farmer"]
  set month item 0 mois
  set canharvest 0
  set year 1
  reset-ticks
end

to nextmonth
  set warn 0
  tick
  set month item ticks mois
  let players1 (list "player 1" "player 2" "player 3" "player 4")
  let animals (list "cow" "sheep" "wolf")
  let gle (list "1" "2" "3" "4")
  let kk 0
  foreach players1 [
    let jj 0
   foreach animals[
     livsim item kk players1 item jj animals
      set jj jj + 1
    ]
    liens item kk gle
    livupdate item kk players1
    set kk kk + 1
  ]
  set kk 0
  set players1 (list feedconc_p1 feedconc_p2 feedconc_p3 feedconc_p4)
  foreach players1 [concfeed item kk players1 set kk kk + 1]
  if month = "November" [user-message "You can now harvest :)"]

  if ticks = 11 [set year year + 1 set month item 0 mois reset-ticks
  user-message "New season! Time to sow"
    ask farmers with [nplot = 7][set offfarm_inc offfarm_inc + 50]
    ask farmers with [nplot != 7][set offfarm_inc offfarm_inc + 10]
    ask farmers [
      set nmanure count out-link-neighbors with [shape = "cow" and canmove = "yes"];1cow=1manure/year
    ]
    ask turtles with [shape = "box"][die]
    ask turtles with [canmove = "yes"][move-to one-of patches with [pcolor = (rgb 0 100 0)]]
    ;ask turtles with [shape = "cow" or shape = "sheep" or shape = "wolf" and canmove = "yes"][set energy 4]
    initbush
    set canharvest 0 ask farmers [set feedfam 0]
    set season one-of (range 0 3 1)
    if season = 0 [set saison "Bad :("]
    if season = 1 [set saison "Good :)"]
    if season = 2 [set saison "Very good :)"]
  ]
  set day day + 1
end
to environment
  ;;ressources
  ask patches with [pxcor = min-pxcor and (pycor != 0 and pycor > min-pycor)][
   set pcolor white
  ]
  ask patches with [pycor = 0 and (pxcor != 0 and pxcor < max-pxcor)][
   set pcolor white
  ]

  ask patches with [pycor = min-pycor and (pxcor != 0 and pxcor < max-pxcor)][
   set pcolor white
  ]

  ask patches with [pxcor = max-pxcor and (pycor != 0 and pycor > min-pycor)][
    set pcolor white
  ]

  ask patches with [pcolor = white] [
    ask neighbors4[
      if pxcor != 0 and pycor > min-pycor and pxcor < max-pxcor [set pcolor white]
    ]
  ]

  ;;bordure
  ask patch 1 0 [set pcolor gray]
  ask patch 0 -1 [set pcolor gray]
  ask patch 1 -1 [set pcolor gray]
  ask patch 0 -11 [set pcolor gray]
  ask patch 1 -12 [set pcolor gray]
  ask patch 11 -12 [set pcolor gray]
  ask patch 12 -11 [set pcolor gray]
  ask patch 11 -11 [set pcolor gray]
  ask patch 12 -1 [set pcolor gray]
  ask patch 11 0 [set pcolor gray]
  ask patch 11 -1 [set pcolor gray]
  ask patch 1 -11 [set pcolor gray]
  ask patch 0 -12 [set pcolor gray]
  ask patch 0 0 [set pcolor gray]
  ask patch 12 -12 [set pcolor gray]
  ask patch 12 0 [set pcolor gray]

  ;;landscape
  ask  patch 2 -6
  [set pcolor rgb 0 255 0
   set plabel "1"
   ask neighbors with [pcolor = black][
      set pcolor rgb 0 255 0
      set plabel "1"
    ]
  ]
  ask patch 2 -4 [
    set pcolor rgb 0 255 0
    set plabel "1"
  ]

  ask patch 6 -10
  [set pcolor rgb 0 255 0
    set plabel "2"
    ask neighbors with [pcolor = black][
      set pcolor rgb 0 255 0
      set plabel "2"
    ]
  ]
  ask patch 4 -10 [
    set pcolor rgb 0 255 0
    set plabel "2"
  ]

  ask patch 10 -6
  [set pcolor rgb 0 255 0
    set plabel "3"
    ask neighbors with [pcolor = black][
      set pcolor rgb 0 255 0
      set plabel "3"
    ]
  ]
  ask patch 8 -6 [
    set pcolor rgb 0 255 0
    set plabel "3"
  ]


  ask patch 6 -2
  [set pcolor rgb 0 255 0
    set plabel "4"
    ask neighbors with [pcolor = black][
      set pcolor rgb 0 255 0
      set plabel "4"
    ]
  ]
  ask patch 4 -2 [
    set pcolor rgb 0 255 0
    set plabel "4"
  ]
  ask patches with [pcolor = rgb 0 255 0][set plabel-color black]

  ;;market
  ask patch 5 -6 [set pcolor rgb 200 200 0]

  ;;bush
  ask patches with [pxcor <= 7 and pycor = -4 and pcolor = black][
    set pcolor rgb 0 100 0
  ]
  ask patch 8 -5 [
    set pcolor rgb 0 100 0
  ]
  ask patch 7 -5 [
    set pcolor rgb 0 100 0
  ]
  ask patches with [pxcor = 7 and pycor > -9 and pycor <= -5] [
    set pcolor rgb 0 100 0
  ]
  ask patches with [pxcor >= 2 and pxcor <= 6 and pycor = -8] [
    set pcolor rgb 0 100 0
  ]
  ask patches with [pxcor >= 2 and pxcor <= 3 and pycor = -9] [
    set pcolor blue
  ]
  ask patches with [pxcor = 3 and pycor <= -2 and pycor >= -3] [
    set pcolor blue
  ]

  ;;position 1
  farmres1 1 (range -2 -11 -1) (list "person farmer" "tile stones" "cow" "wolf" "sheep" "bird" "drop" "car" "truck")
  (list 15 37 85 5 135 116 95 85 44) (list "famer" "land" "cattle" "donkey" "srum" "poultry" "fertilizer" "cart" "tricycle") 1

  farmres1 0 (range -3 -10 -1) (list "checker piece 2" "tile water" "lightning" "triangle" "coin tails" "coin tails" "dot")
  (list 25 45 75 35 55 95 125) (list "grain" "residue" "conc" "manure" "onfarm inc" "off-farm inc" "seed") 1

  ;;position 2
  farmres2 -11 (range 2 11 1) (list "person farmer" "tile stones" "cow" "wolf" "sheep" "bird" "drop" "car" "truck")
  (list 15 37 85 5 135 116 95 85 44)(list "famer" "land" "cattle" "donkey" "srum" "poultry" "fertilizer" "cart" "tricycle") 2

  farmres2 -12 (range 3 10 1) (list "checker piece 2" "tile water" "lightning" "triangle" "coin tails" "coin tails" "dot")
  (list 25 45 75 35 55 95 125) (list "grain" "residue" "conc" "manure" "onfarm inc" "off-farm inc" "seed") 2

  ;;position 3
  farmres1 11 (range -2 -11 -1) (list "person farmer" "tile stones" "cow" "wolf" "sheep" "bird" "drop" "car" "truck")
  (list 15 37 85 5 135 116 95 85 44) (list "famer" "land" "cattle" "donkey" "srum" "poultry" "fertilizer" "cart" "tricycle") 3

  farmres1 12 (range -3 -10 -1) (list "checker piece 2" "tile water" "lightning" "triangle" "coin tails" "coin tails" "dot")
  (list 25 45 75 35 55 95 125) (list "grain" "residue" "conc" "manure" "onfarm inc" "off-farm inc" "seed") 3

  ;;position 4
  farmres2 -1 (range 10 1 -1) (list "person farmer" "tile stones" "cow" "wolf" "sheep" "bird" "drop" "car" "truck")
  (list 15 37 85 5 135 116 95 85 44) (list "famer" "land" "cattle" "donkey" "srum" "poultry" "fertilizer" "cart" "tricycle") 4

  farmres2 0 (range 9 2 -1) (list "checker piece 2" "tile water" "lightning" "triangle" "coin tails" "coin tails" "dot")
  (list 25 45 75 35 55 95 125) (list "grain" "residue" "conc" "manure" "onfarm inc" "off-farm inc" "seed") 4

  playerplace

  set farmi (list "1" "2" "3" "4")
  let playi (list player1type player2type player3type player4type)
  let ii 0
  foreach farmi [
    resdistrib item ii playi item ii farmi
    liens item ii farmi
    set ii ii + 1
  ]
  initbush
  let players (list "player 1" "player 2" "player 3" "player 4")
  let animals (list "cow" "sheep" "wolf" "bird")
  let gle (list "1" "2" "3" "4")
  let kk 0
  foreach players [
    let jj 0
   foreach animals[
     livsim item kk players item jj animals
      set jj jj + 1
    ]
    ;liens item kk gle
    ask farmers with [player = item kk players][
      let nb nconc
      let nfert nfertilizer
      ask out-link-neighbors with [shape = "lightning"] [
       hatch nb
      ]

      ask out-link-neighbors with [shape = "drop"][
        hatch nfert [
          set typo "fertilizer"
          set shape "drop"
          set color 97
          set size .5
        ]
      ]
      ask out-link-neighbors with [shape = "triangle"][
        hatch nfert [
          set typo "manure"
          set shape "triangle"
          set color 36
          set size .5
        ]
      ]
    ]

    liens item kk gle
    livupdate item kk players
    set kk kk + 1
  ]
  ;set kk 0

  ;foreach players [
  ;ask farmers with [player = item kk players][
  ;  ask out-link-neighbors with [shape = "drop" and color = 97][
  ;   die
  ;  ]
  ;]

   ; set kk kk + 1]

end

to farmres1 [p i j col typ ps]
  ;;function to dispose resources
  ;; vertical disposition
  let n 0
  foreach i [
    create-turtles 1 [
      let l item n i
      move-to patch p l
      set shape item n j
      set color item n col
      set pos ps
      set typo item n typ
    ]
    set n n + 1
  ]
end
to farmres2 [p i j col typ ps]
  ;;function to dispose resources
  ;; horizontal disposition
  let n 0
  foreach i [
    create-turtles 1 [
      let l item n i
      move-to patch l p
      set shape item n j
      set color item n col
      set pos ps
      set typo item n typ
    ]
    set n n + 1
  ]

end

to playerplace
  set farmers turtles with [shape = "person farmer"]
  ask farmers with [pos = player1pos] [set player "player 1"]
  ask turtles with [pos = player1pos] [set farm "1"]

  ask farmers with [pos = player2pos] [set player "player 2"]
  ask turtles with [pos = player2pos] [set farm "2"]

  ask farmers with [pos = player3pos] [set player "player 3"]
  ask turtles with [pos = player3pos] [set farm "3"]

  ask farmers with [pos = player4pos] [set player "player 4"]
  ask turtles with [pos = player4pos] [set farm "4"]

  ask turtles [set label farm set label-color red]
  ;;avoid more than one player per position
  let playpos (list player1pos player2pos player3pos player4pos)
  if sum playpos != 10 [
    user-message "More than one player in a position. Please check players position, reset and start again"
    stop
  ]
end

to resdistrib [typology ferme]
  ;; Subsistence-oriented crop farm
  if typology = "SOC" [

    ask turtles with [shape = "person farmer" and farm = ferme][
      set family_size 8
      set nplot 5
      set ncow one-of (range 0 4 1)
      set nsrum one-of (range 0 11 1)
      set npoultry one-of (range 3 11 1)
      set nfertilizer one-of (range 0 4 1)
      set ncart one-of (range 0 2 1)
      ifelse ncart > 0 [set ndonkey one-of (range 1 3 1)][set ndonkey one-of (range 0 3 1)]
      set ntricycle 0
      set ngrain 2
      set nresidue 0
      set nconc one-of (range 0 4 1)
      set nmanure one-of (range 4 11 1)
      set onfarm_inc 20
      set offfarm_inc 10
    ]

  ]

  ;; Subsistence-oriented livestock farm
  if typology = "SOL" [

    ask turtles with [shape = "person farmer" and farm = ferme][
      set family_size 7
      set nplot 4
      set ncow one-of (range 0 3 1)
      set nsrum one-of (range 4 13 1)
      set npoultry one-of (range 2 16 1)
      set nfertilizer one-of (range 0 3 1)
      set ncart one-of (range 0 2 1)
      ifelse ncart > 0 [set ndonkey one-of (range 1 2 1)][set ndonkey one-of (range 0 2 1)]
      set ntricycle 0
      set ngrain 2
      set nresidue 0
      set nconc one-of (range 0 4 1)
      set nmanure one-of (range 3 11 1)
      set onfarm_inc 25
      set offfarm_inc 10
    ]

  ]

  ;; Market-oriented diversified farm
  if typology = "MOD" [

    ask turtles with [shape = "person farmer" and farm = ferme][
      set family_size 12
      set nplot 7
      set ncow one-of (range 0 4 1)
      set ndonkey one-of (range 1 3 1)
      set nsrum one-of (range 5 18 1)
      set npoultry one-of (range 8 23 1)
      set nfertilizer one-of (range 0 4 1)
      set ncart 1
      set ntricycle one-of (range 0 2 1)
      set ngrain 2
      set nresidue 0
      set nconc one-of (range 0 6 1)
      set nmanure one-of (range 5 11 1)
      set onfarm_inc 100
      set offfarm_inc 50
    ]

  ]

  ;; Land-constrained livestock farm
  if typology = "LCL" [

    ask turtles with [shape = "person farmer" and farm = ferme][
      set family_size 15
      set nplot 3
      set ncow one-of (range 2 7 1)
      set ndonkey one-of (range 0 3 1)
      set nsrum one-of (range 9 52 1)
      set npoultry one-of (range 0 28  1)
      set nfertilizer one-of (range 0 2 1)
      set ncart one-of (range 0 2 1)
      ifelse ncart > 0 [set ndonkey one-of (range 1 3 1)][set ndonkey one-of (range 0 3 1)]
      set ntricycle 0
      set ngrain 3
      set nresidue 0
      set nconc one-of (range 7 21 1)
      set nmanure one-of (range 3 8 1)
      set onfarm_inc 100
      set offfarm_inc 10
    ]

  ]

end

to sow
  ifelse month = "July" [
    ;set farmers turtles with [shape = "person farmer"]
    ask turtles-on patches with [pcolor = rgb 0 255 0][die]
    set farmi [farm] of farmers
    let n 0
    let m 0
    foreach farmi [
      ask turtles with [farm = item n farmi and shape = "person farmer"][
        ;show nplot
        let nseed nplot
        let nfert nfertilizer
        let nman nmanure
        let posi pos
        ask patches with [plabel = ""][set plabel "99"]
        let fin patches with [(read-from-string plabel) = posi and pcolor != white]
        ask patch-here[
          sprout nseed [
            set typo "seed2"
            set farm item n farmi
            set label farm
            set shape "dot"
            set color 125
            move-to one-of fin with [count turtles-here = 0]
          ]
          sprout nman [
           set typo "manure"
           set shape "triangle"
           set color 35
           set size .5
           move-to one-of fin with [count turtles-here >= 1]
            if count turtles-here with [typo = "manure"] > 2 [
              if any? patches with [(read-from-string plabel) = posi and pcolor != white
                and count turtles-here with [typo = "manure"] < 2 and count turtles-here with [typo = "seed2"] > 0][
                let destination patches with [(read-from-string plabel) = posi and pcolor != white
                and count turtles-here with [typo = "manure"] < 2 and count turtles-here with [typo = "seed2"] > 0]
                move-to one-of destination;; try to put max of 2 manure per plot as beyond yield do not increase
              ]
            ]
          ]

          sprout nfert [
           set typo "fertilizer"
           set shape "drop"
           set color 95
           set size .5
           move-to one-of fin with [count turtles-here >= 1]
            if count turtles-here with [typo = "fertilizer"] > 2 [
              if any? patches with [(read-from-string plabel) = posi and pcolor != white
              and count turtles-here < 5 and count turtles-here with [typo = "seed2"] > 0][
                let destination patches with [(read-from-string plabel) = posi and pcolor != white
                and count turtles-here with [typo = "fertilizer"] < 2 and count turtles-here with [typo = "seed2"] > 0]
                move-to one-of destination;; try to put max of 2 fertilizer per plot as beyond yield do not increase
              ]
            ]
          ]

        ]

      ]
    ;show farmi
      ;show xseed
      ;ask turtles with [farm = item n farmi and shape = "person farmer"][
       ; set nfertilizer 0 set nmanure 0
      ;]
      set n n + 1
    ]
    ask turtles-on patches with [pcolor = rgb 0 255 0][set label ""]
    ask patches with [plabel = "99"][set plabel ""]
    let seeds turtles with [typo = "seed2"]
    ask farmers [set nmanure 0 set nfertilizer 0 set ngrain 0]
    ask turtles with [typo = "fertilizer" and color = 96][die]
    ask turtles with [typo = "fertilizer" and color = 97][die]
    ask turtles with [typo = "manure" and color = 36][die]

  ]
  [user-message "You cannot sow, wait for July"]

end

to grow [taille]
  let g ""; variable to check the period is suitable for growing crops
  if month = "August" [set taille .5 set g "ok"]
  if month = "September" [set taille .75 set g "ok"]
  if month = "October" [set g "ok"]
  if g = "ok" [
    ask turtles-on patches with [pcolor = rgb 0 255 0][
      ask turtles-here with [typo = "seed2" or typo = "crop"][
        ask patch-here [
          if month = "August"[
            sprout 1 [
              set typo "crop"
              set shape "flower"
              set size taille
              set color yellow
            ]
            set cultiv "yes"
          ]
        ]
      ]
    ]

    ifelse month != "August" [
      ask turtles with [typo = "crop" ][
        set size 0.75
      ]
    ]
    [ask turtles-on patches with [pcolor = rgb 0 255 0][
      ask turtles-here with [typo = "seed2" or typo = "fertilizer" or typo = "manure"][
        ask patch-here [
          set ferti count turtles-here with [typo = "fertilizer"]
          set manu count turtles-here with [typo = "manure"]
        ]

        die
      ]
      ]
    ]
    produce;;calculate harvest and display it
  ]

  bush
end

to produce
  ;set farmers turtles with [shape = "person farmer"]
  set farmi [farm] of farmers
  let n 0

  ;;basic prod according ot season
  if season = 0 [set ngseason 1 set nrseason 15]
  if season = 1 [set ngseason 2 set nrseason 18]
  if season = 2 [set ngseason 3 set nrseason 20]
  if month = "October" [
    ask patches with [plabel = ""][set plabel "99"]
    foreach farmi [

      ask farmers with [farm = item n farmi] [
        let posi pos
        set cultivplot patches with [(read-from-string plabel) = posi and cultiv = "yes"]

        ;;gain of grain and residue due to fertilizer
        ask cultivplot with [ferti > 0][
          if ferti > 2 [set ferti 2]; even if there is more than 2 only 2 will contribute to production
          sprout ferti [
            set typo "grain"
            set shape "cylinder"
            set size .75
            set color red
            set farm item n farmi
          ]

          sprout ferti [
            set typo "residue"
            set shape "star"
            set size .5
            set color yellow
            set farm item n farmi
          ]
        ]
        ;;gain of residue due to manure
        ask cultivplot with [manu > 0][
          if manu > 2 [set manu 2]
          sprout manu [
            set typo "residue"
            set shape "star"
            set size .5
            set color yellow
            set farm item n farmi
          ]
        ]
       ;;normal production depending on season
      ask cultivplot [

          sprout ngseason [
            set typo "grain"
            set shape "cylinder"
            set size .75
            set color red
            set farm item n farmi
          ]
          sprout nrseason [
            set typo "residue"
            set shape "star"
            set size .5
            set color yellow
            set farm item n farmi
          ]
        ]

        ]

        set n n + 1
        ]


      ask patches with [plabel = "99"][set plabel ""]
    ask turtles with [shape = "flower"][die]
    ]


end

to harvest [presid gamer]
  ;;presid is the proportion of residue harvested, see interface
  let farmii item 0 [farm] of farmers with [player = gamer]
  if month = "November" [
    ifelse canharvest < 4 [
    ask turtles with [typo = "grain" and shape = "cylinder"][
        set hidden? true
        ask patch-here [set harvested "yes"]
    ]

      ask farmers with [player = gamer] [
        ;;check if farm have resource to harvest a certain prop of biom
        if (presid / 100) > 0.5 [if ncart = 0 [
          user-message (word "You do not own a donkey cart or tricycle, you can harvest a maximum of 50% of your crop residue."
            " Update the proportion of residue to be harvested and try to harvest again.")
          stop
        ]]

        if (presid / 100) > 0.8 [ifelse ntricycle >= 1 [set presid presid][
          user-message (word "You do not own a tricycle, you can harvest a maximum of 80% of your crop residue."
            " Update the proportion of residue to be harvested and try to harvest again.")
          stop
      ]]

      liens farmii

      let tresid count out-link-neighbors with [typo = "residue" and shape = "star"]
      set tresid ceiling (tresid * presid / 100)
        ask n-of tresid out-link-neighbors with [typo = "residue" and shape = "star"] [
          set hidden? true
        ]

        ;;update grain and residue info in farms
        set graine count out-link-neighbors with [typo = "grain" and shape = "cylinder"]
        set resid count out-link-neighbors with [typo = "residue" and hidden? = true]
        set ngrain graine ;- 1; remove the ficitve one white plot
        set nresidue resid ;- 1; remove the ficitve one white plot
        set nresiduep count out-link-neighbors with [typo = "residue" and hidden? = false and shape = "star"];;residue on field
      ]

      ask turtles with [typo = "residue" and shape = "star"] [set open "yes"]
    ][user-message "You already harvested"]
    set canharvest canharvest + 1
  ]
  ;[user-message "You cannot harvest, it is only possible in November"]
  ;if month = "November" and canharvest <= 4 [user-message "Feed your family with the grain harvested before next step"]
end

to initbush
  set bushplot patches with [pcolor = rgb 0 100 0]
  let nbush count bushplot
  set nbush nbush * 9

  create-turtles nbush [
    set shape "box"
    set size .25
    set color 135
    move-to one-of bushplot; with [count turtles-here with [shape = "box"] < ]
  ]

end

to bush
  ifelse (month = "August" or month = "September" or month = "October")[
    ask bushplot [
      sprout 5 [
        set shape "box"
        set size .25
        set color 135
      ]
    ]
  ]
  [
    ask bushplot with [count turtles-here with[shape = "box"] > 0][
      if count turtles-here with[shape = "box"] = 1 [
        ask one-of turtles-here with[shape = "box"][die]]
      if count turtles-here with[shape = "box"] >= 2 [
        ask n-of 2 turtles-here with[shape = "box"][die]]
    ]


  ]

end

to livsim [gamer animal]
  let farmlab item 0 [label] of farmers with [player =  gamer]
  let coul 0
  let nanim 0
  let sz 0;size of animals
  set maxc count farmers with [ncow > 0]
  set maxr count farmers with [nsrum > 0]
  set maxd count farmers with [ndonkey > 0]
  set maxp count farmers with [npoultry > 0]
  set maxrc maxc + maxr + maxd + maxp
  ifelse animal = "cow" [
    set coul cyan
    set maxc count farmers with [ncow > 0]
  ] [
    set coul white
    set maxc count farmers with [nsrum > 0]
  ]
  if animal = "wolf" [set coul gray]
  if animal = "bird" [set coul 116]
  ;;create cows

  if cc <= maxrc [
    set cc cc + 1
    ask farmers with [player = gamer][
      if animal ="cow" [set nanim ncow set sz 1]
      if animal = "sheep"[set nanim nsrum set sz .75]
      if animal = "wolf"[set nanim ndonkey set sz 1]
      if animal = "bird"[set nanim npoultry set sz 1]
      ifelse animal != "bird" [
        ask out-link-neighbors with [shape = animal and canmove = 0][
          hatch nanim [
            set color coul
            set size sz
            set energy 4
            set state "skinny"
            set repro "no"
            set canmove "yes"
            move-to one-of patches with [pcolor = (rgb 0 100 0)]
          ]
        ]
      ][
        ask out-link-neighbors with [shape = animal][
          hatch nanim [
            set color coul
            set size sz
            set energy 4
            set state "skinny"
            set repro "no"
          ]
        ]
      ]
  ]]

  liens farmlab

   ;;cows movements on bushplot
  let cow turtles with [shape = animal and canmove = "yes" and farm = farmlab]
  ask cow with [grazed != "yes"][
    if (count turtles-here with [shape = animal and canmove = "yes"]) >
    (count turtles-here  with[shape = "box"])[
      if any? bushplot with [count turtles-here with [shape = animal and canmove = "yes"] <
        count turtles-here with [shape = "box"]] [
        move-to patch-here
      ]
    ]
  ]
  ask cow with [grazed != "yes"] [
    ifelse any? turtles-here with[shape = "box"][][
      if any? turtles with[shape = "box"] [
        move-to one-of bushplot with [count turtles with [shape = "box"] > 0]
      ]
    ]

  ]
  ;;eating grass
  let kil 0
  let kild 0
  ask cow with [grazed != "yes"][
    if any? turtles-here with[shape = "box"] [
        ifelse (animal = "cow" or animal = "wolf") [
          ask one-of turtles-here with[shape = "box" ][die]
          set energy energy + 1 set grazed "yes"
        ]

        [
          ask one-of turtles-here with[shape = "box"][die]
          set energy energy + 1 set grazed "yes"
        ]
      ;set energy energy + 1
      ;set grazed "yes"
    ]
  ]

  grazeresidue gamer animal
  directfeed gamer

  ;;manure left on 30% of bushplot. only happens after January
  ;if (month != "July" and month != "August" and month != "September" and month != "October" and
   ; month != "December" and month != "January")[

   ; if count bushplot with [count turtles with [shape = "box"] > 0
   ;   and count turtles with [shape = "triangle"] > 0
   ; ] = 0 [

   ;   if mn = 0
    ;  [
   ;     set mn 1
   ;     let nbp count bushplot
   ;     set nbp nbp / 3
   ;     create-turtles nbp [
   ;       set shape "triangle"
   ;       set color 35
   ;       set typo "manure"
   ;       move-to one-of bushplot with [count turtles-here with [shape = "triangle"] = 0]
    ;    ]
   ;   ]
   ; ]
  ;]

  reproduce gamer animal

  ask cow with [grazed = "yes"] [set grazed ""]
end

to grazeresidue [gamer animal]
  let farmlab item 0 [label] of farmers with [player =  gamer]
  let farmpos item 0 [pos] of farmers with [player =  gamer]
  let cow turtles with [shape = animal and canmove = "yes" and farm = farmlab]

     ;;cows movements on agricultural plots
  ask cow with [grazed != "yes"][if any? turtles with [shape = "star" and open = "yes" and farm = farmlab and hidden? = false][
    move-to one-of turtles with [shape = "star" and open = "yes" and farm = farmlab and hidden? = false]
    ]
  ]


  ask cow with [grazed != "yes"][
    ifelse any? turtles-here with[shape = "star" and open = "yes" and farm = farmlab][][
      if any? turtles with[shape = "star" and open = "yes" and farm = farmlab and hidden? = false] [
        move-to one-of cultivplot with [count turtles-here with [shape = "star" and open ="yes" and farm = farmlab and hidden? = false] > 0]
      ]
    ]

  ]


  ;;eating residue
  let kil 0
  let kild 0
  ask cow with [grazed != "yes"][
    if any? turtles-here with[shape = "star" and farm = farmlab and hidden? = false] [
      ask turtles-here with[shape = "star" and farm = farmlab and hidden? = false] [
        ifelse (animal = "cow" or animal = "wolf") [
          set kil count turtles-here with [(shape = "cow" or shape ="wolf") and farm = farmlab]
          set kild count turtles-here with [shape = "star" and farm = farmlab and hidden? = false]
          if kil > kild [set kil kild]
          ask n-of kil turtles-here with[shape = "star" and farm = farmlab and hidden? = false][die]
        ]

        [
          if count turtles-here with [shape = "sheep" and farm = farmlab and hidden? = false] = 1 [
            ifelse neat = 2 [
              ask one-of turtles-here with[shape = "star" and farm = farmlab and hidden? = false and neat = 2][die]
            ]

            [ set neat neat + 1]
          ]
          if count turtles-here with [shape = "sheep" and farm = farmlab] >= 2 [
            set kil count turtles-here with [shape = "sheep" and farm = farmlab]
            set kild count turtles-here with [shape = "star" and farm = farmlab and hidden? = false]
            if (kil / 2) > kild [set kil kild]
            ask n-of ceiling (kil / 2) turtles-here with[shape = "star" and farm = farmlab and hidden? = false] [die]
          ]
        ]
      ]
      set energy energy + 1
      set hunger 0
      set grazed "yes"
    ]
  ]

end

to livupdate [gamer]

  ask farmers with [player = gamer][
    set ncow count out-link-neighbors with[shape = "cow" and canmove = "yes" and [pcolor] of patch-here != white]
    set nsrum count out-link-neighbors with[shape = "sheep" and canmove = "yes" and [pcolor] of patch-here != white]
    set ndonkey count out-link-neighbors with[shape = "wolf" and canmove = "yes" and [pcolor] of patch-here != white]
    set npoultry count out-link-neighbors with[shape = "bird"] - 1; remove the ficitve one
    set ngrain count out-link-neighbors with[shape = "cylinder" and [pcolor] of patch-here != white]
    set nconc count out-link-neighbors with[typo = "conc"] - 1; remove the ficitve one
    ;ifelse ticks > 1 [set nfertilizer count out-link-neighbors with[typo = "fertilizer"] - 1]; remove the ficitve one
    ;[ifelse nf < 1 [set nfertilizer nfertilizer + count out-link-neighbors with[typo = "fertilizer"] - 1 set nf nf + 1]
    ;  [set nfertilizer count out-link-neighbors with[typo = "fertilizer"] - 1]
    ;]
    set nfertilizer count out-link-neighbors with[typo = "fertilizer"] - 1
    set nmanure count out-link-neighbors with[typo = "manure"] - 1
  ]
end

to directfeed [gamer]
  let farmlab item 0 [farm] of farmers with [player = gamer]
  if (count turtles with [(shape = "cow" or shape = "sheep" or shape = "wolf") and hunger > 0 and farm = farmlab] > 0) [
    ask farmers with [player = gamer][
      set forage count out-link-neighbors with [shape = "star" and hidden? = true]
      let fourrage forage

      ;;case of animal with 0 energy, cow > wolf > srum
      emergencyfeed gamer "cow"
      if forage < 0 [set forage 0]
      emergencyfeed gamer "wolf"
      if forage < 0 [set forage 0]
      emergencyfeed gamer "sheep"

      if forage < 0 [set forage 0]
      let reste fourrage - forage
      let tofeed1 count out-link-neighbors with [(shape ="cow" or shape = "wolf") and canmove = "yes" and grazed = ""]
      let tofeed2 count out-link-neighbors with [shape = "sheep" and canmove = "yes" and grazed = ""]
      let ration (1 * tofeed1 + .5 * tofeed2);1 star =1cow/donkey = 2 small rum

      ifelse forage < ration [
        set ration forage if ration > tofeed1 [set ration tofeed1];;ration should be <= ncow + ndonkey (tofeed1)
        set tofeed2 forage - tofeed1 if tofeed2 < 0 [set tofeed2 0];; the remaining ration goes to srum

        ask n-of ration out-link-neighbors with [(shape ="cow" or shape = "wolf") and canmove = "yes" and grazed = ""][
          set energy energy + 1
          set hunger 0
          set grazed "yes"
        ]

        ask n-of tofeed2 out-link-neighbors with [shape = "sheep" and canmove = "yes" and grazed = ""][
          set energy energy + 1
          set hunger 0
          set grazed "yes"
        ]

      ][
        ask n-of tofeed1 out-link-neighbors with [(shape ="cow" or shape = "wolf") and canmove = "yes" and grazed = ""][
          set energy energy + 1
          set hunger 0
          set grazed "yes"
        ]

        ask n-of tofeed2 out-link-neighbors with [shape = "sheep" and canmove = "yes" and grazed = ""][
          set energy energy + 1
          set hunger 0
          set grazed "yes"
        ]
      ]
      ;;diminish forage stock
      set ration ration + reste
      ask n-of (ceiling ration) out-link-neighbors with [shape = "star" and hidden? = true][
        die
      ]
    ]

  ]

end

to emergencyfeed [gamer animal]
  let fac 0
  let frg forage
  ifelse animal = "sheep" [set fac 2][set fac 1]
  ask farmers with [player = gamer][
  let riskyc count out-link-neighbors with [shape = animal and canmove = "yes" and hunger > 0]
    if riskyc > 0 [ifelse (forage * fac) > riskyc [
      ask n-of riskyc out-link-neighbors with [shape = animal and canmove = "yes" and hunger > 0][
        set energy energy + 1
        set hunger 0
        set grazed "yes"
        set forage forage - floor riskyc / fac
      ]]
          [ask n-of (forage * fac) out-link-neighbors with [shape = animal and canmove = "yes" and hunger > 0][
        set energy energy + 1
        set hunger 0
        set grazed "yes"
        set forage 0
      ]]
     ; ask n-of (ceiling frg - forage) out-link-neighbors with [shape = "star" and hidden? = true][
      ;  die
     ; ]
  ]]
end

to concfeed [gamer]
  let app "no"; apply conc feed or not

  if gamer = "yes_1" [set gamer "player 1" set app "yes"]
  if gamer = "yes_2" [set gamer "player 2" set app "yes"]
  if gamer = "yes_3" [set gamer "player 3" set app "yes"]
  if gamer = "yes_4" [set gamer "player 4" set app "yes"]

  if app = "yes" [

    ask farmers with [player = gamer][
      let cow out-link-neighbors with [shape = "cow" and canmove = "yes"]
      set forage nconc
      let fourrage forage
      let rest 0

      ;;case of animal with 0 energy, cow > wolf > srum
      emergencyfeed gamer "cow"
      if forage < 0 [set forage 0]
      emergencyfeed gamer "wolf"
      if forage < 0 [set forage 0]
      emergencyfeed gamer "sheep"

      if forage < 0 [set forage 0]
      let nanim forage

      ifelse count cow > 0 [
        if forage >= count cow [set nanim count cow set rest forage - nanim]
        ask n-of nanim cow [
          set energy energy + 1 ; 1 unit conc = 1 cattle for 1 month
        ]
      ][
        let srum out-link-neighbors with [shape = "sheep" and canmove = "yes"]
        set nanim forage * 2;1 unit conc = 2 sheep for 1 month
        if nanim >= count srum [set nanim count srum set rest (forage * 2 - nanim) / 2]
        ask n-of nanim srum [
          set energy energy + 1
        ]
      ]
      ask n-of (ceiling fourrage - forage) out-link-neighbors with [typo = "conc"][
       die
      ]
     ; set nconc rest
    ]

  ]
end



to liens [ferme]
   ask farmers with [farm = ferme] [
        create-biom_owner-to other turtles with [farm = ferme][
          set color red hide-link
        ]
  ]
end

to farmlink
  ask farmers [
    create-biom_transfer-to other farmers[
          set color blue hide-link
        ]
  ]

end


to biomfluxes [sender receiver biomsent biomreceiv]
  liens "1" liens "2" liens "3" liens "4"

  let biomsown 0;biomass own by sender
  let biomrown 0;biomass own by receiver

  if biomsent = "concentrate" [set biomsent "conc"]
  if biomsent = "small ruminant" [set biomsent "srum"]
  if biomreceiv = "concentrate" [set biomreceiv "conc"]
  if biomreceiv = "small ruminant" [set biomreceiv "srum"]

  ifelse biomsent != "money"[
    ask farmers with [player = sender][
      ifelse biomsent != "conc" and biomsent != "poultry" and biomsent != "manure"[
        set biomsown count out-link-neighbors with [typo = biomsent and [pcolor] of patch-here != white ]]
        [set biomsown count out-link-neighbors with [typo = biomsent]]
      ]
    ][set biomsown item 0[onfarm_inc] of farmers with [player = sender ] + item 0[offfarm_inc] of farmers with [player = sender ]]

    ifelse biomreceiv != "money" [
      ask farmers with [player = receiver][
        ifelse biomreceiv != "conc" and biomreceiv != "poultry" and biomreceiv != "manure"[
        set biomrown count out-link-neighbors with [typo = biomreceiv and [pcolor] of patch-here != white ]]
          [set biomrown count out-link-neighbors with [typo = biomreceiv]]
        ]
      ][set biomrown item 0[onfarm_inc] of farmers with [player = receiver] + item 0[offfarm_inc] of farmers with [player = receiver]]

  if biomsent = "poultry" [set biomsown biomsown - 1]; remove the fictive one
  if biomreceiv = "poultry" [set biomrown biomrown - 1]
      ;PM:think of case it is a gift
  if biomass_sent_amount > biomsown [user-message "Sender: you cannot send more biomass than you own. Please try again" stop]
  if biomass_in_amount > biomrown [user-message "Receiver: you cannot send more biomass than you own. Please try again" stop]

  ;;biomass exchange
  biomexchange sender receiver biomsent biomreceiv

  ask biom_owner [die]
  liens "1" liens "2" liens "3" liens "4"
  livupdate sender
  livupdate receiver

end

to biomexchange [sender receiver biomsent biomreceiv]
  let biom_out biomass_sent_amount
  let biom_in biomass_in_amount
  ask farmers with [player = sender][
    ifelse biomsent != "money"[
      ifelse biomsent != "conc" and biomsent != "poultry"  and biomsent != "manure"[
      ask n-of biom_out out-link-neighbors with [typo = biomsent and [pcolor] of patch-here != white][
        set farm item 0[farm] of farmers with [player = receiver]
      ]][
        ask n-of biom_out out-link-neighbors with [typo = biomsent][
        set farm item 0[farm] of farmers with [player = receiver]
      ]]
    ][
     ifelse  (onfarm_inc - biom_out) >= 0[
        set onfarm_inc onfarm_inc - biom_out]
      [set offfarm_inc offfarm_inc - biom_out + onfarm_inc set onfarm_inc 0]
      ask farmers with [player = receiver][set onfarm_inc onfarm_inc + biom_out]
    ]
  ]


  ask farmers with [player = receiver][
    ifelse biomreceiv != "money"[
        ifelse biomreceiv != "conc" and biomreceiv != "poultry" and biomreceiv != "manure"[
      ask n-of biom_in out-link-neighbors with [typo = biomreceiv and [pcolor] of patch-here != white][
        set farm item 0[farm] of farmers with [player = sender]
      ]][
          ask n-of biom_in out-link-neighbors with [typo = biomreceiv][
        set farm item 0[farm] of farmers with [player = sender]
        ]]
    ][
      ifelse  (onfarm_inc - biom_in) >= 0[
        set onfarm_inc onfarm_inc - biom_in]
      [set offfarm_inc offfarm_inc - biom_in + onfarm_inc set onfarm_inc 0 ]
      ask farmers with [player = sender][set onfarm_inc onfarm_inc + biom_in]
    ]
  ]
end


to market-sell [gamer biomass weigh]
  let bonus 0;for livestock in dec, apr, june
  let bonus2 0;for grain in april-june
  let bonus3 0; for tricycle
  if biomass = "tricycle" [set bonus3 2]
  if month = "December" or month = "April" or month = "June" [set bonus 1]
  if month = "April" or month = "May" or month = "June" [set bonus2 1]
  let etat ""
  let qsell 0
  if biomass = "concentrate" [set biomass "conc"]
  if biomass = "small ruminant" [set biomass "srum"]

  ifelse biomass != "cart" and biomass != "tricyle" and biomass != "poultry" [
    ask farmers with [player = gamer][
      set qsell count out-link-neighbors with [typo = biomass and [pcolor] of patch-here != white and state = weigh]]
  ]
  [ifelse biomass = "cart" [set qsell item 0[ncart] of farmers with [player = gamer]][set qsell item 0[ntricycle] of farmers with [player = gamer]]]

  if biomass = "poultry" [ifelse sell_how_much < 10 and sell_how_much != 0[user-message "You cannot sell less than 10 poultry" stop]
    [set qsell item 0[npoultry] of farmers with [player = gamer]]
  ]

  if biomass = "fertilizer" [set qsell item 0[nfertilizer] of farmers with [player = gamer]]
  if biomass = "conc" [set qsell item 0[nconc] of farmers with [player = gamer]]
  if biomass = "grain" [set qsell item 0[ngrain] of farmers with [player = gamer]]
  if biomass = "manure" [set qsell item 0[nmanure] of farmers with [player = gamer]]

  if sell_how_much > qsell [user-message "You cannot sell more than you have" stop]
  ifelse biomass != "cart" and biomass != "tricycle" and biomass != "poultry"
  and biomass != "tricycle" and biomass != "fertilizer" and biomass != "conc" and biomass != "manure"[
    ask farmers with [player = gamer][
      ask n-of sell_how_much out-link-neighbors with [typo = biomass and [pcolor] of patch-here != white and state = weigh][
        set etat state
        die
      ]
      if biomass = "cattle" [
        if etat = "skinny"[set onfarm_inc onfarm_inc + (6 + bonus) * sell_how_much]; * sell_how_much
        if etat = "medium"[set onfarm_inc onfarm_inc + (8 + bonus) * sell_how_much]
        if etat = "fat"[set onfarm_inc onfarm_inc + (10 + bonus) * sell_how_much]
      ]
      if biomass = "srum" [
        if etat = "skinny"[set onfarm_inc onfarm_inc + (1 + bonus) * sell_how_much]
        if etat = "medium"[set onfarm_inc onfarm_inc + (2 + bonus) * sell_how_much]
        if etat = "fat"[set onfarm_inc onfarm_inc + (3 + bonus) * sell_how_much]
      ]
      if biomass = "donkey" [
        if etat = "skinny"[set onfarm_inc onfarm_inc + (3 + bonus) * sell_how_much]
        if etat = "medium"[set onfarm_inc onfarm_inc + (5 + bonus) * sell_how_much]
        if etat = "fat"[set onfarm_inc onfarm_inc + (6 + bonus) * sell_how_much]
      ]
      if biomass = "residue" or biomass = "grain" [set onfarm_inc onfarm_inc + (2 + bonus2) * sell_how_much]
    ]
  ][
    ask farmers with [player = gamer][
      ifelse biomass = "cart" and biomass = "tricycle" [
        set onfarm_inc onfarm_inc + (6 + bonus3) * sell_how_much]
      [if biomass = "poultry"[set onfarm_inc onfarm_inc + (1 + bonus) * (sell_how_much / 10)];1unit of money = 10 poultry
       if biomass = "fertilizer" [set onfarm_inc onfarm_inc + 1 * sell_how_much]
        if biomass = "conc" [set onfarm_inc onfarm_inc + (2 + bonus2) * sell_how_much]
        if biomass = "manure" [set onfarm_inc onfarm_inc + (2 + bonus2) * sell_how_much]
      ]

      ask n-of sell_how_much out-link-neighbors with [typo = biomass][
        die
      ]

  ]]
end

to market-buy [gamer biomass]
  let bonus 0;for livestock in dec, apr, june
  let bonus2 0;for grain in april-june
  let bonus3 0; for tricycle
  if biomass = "tricycle" [set bonus3 2]
  if month = "December" or month = "April" or month = "June" [set bonus 1]
  if month = "April" or month = "May" or month = "June" [set bonus2 1]
  let etat ""
  let qbuy 0
  ask patches with [plabel = ""][set plabel "99"]
  if biomass = "concentrate" [set biomass "conc"]
  if biomass = "small ruminant" [set biomass "srum"]

  ifelse (biomass != "cart" and biomass != "tricycle")[
    ask farmers with [player = gamer][
      let inc onfarm_inc + offfarm_inc
      if biomass = "cattle" [
        set qbuy (6 + bonus) * buy_how_much
        ifelse inc < qbuy [user-message "You do not have enough money" stop] [
          ifelse qbuy > onfarm_inc[
            set offfarm_inc inc - qbuy
            set onfarm_inc 0
          ][set onfarm_inc onfarm_inc - qbuy]
        ]
      ]

        if biomass = "srum" [
        set qbuy (1 + bonus) * buy_how_much
        ifelse inc < qbuy [user-message "You do not have enough money" stop] [
          ifelse qbuy > onfarm_inc[
            set offfarm_inc inc - qbuy
            set onfarm_inc 0
          ][set onfarm_inc onfarm_inc - qbuy]
        ]
      ]

        if biomass = "donkey" [
        set qbuy (3 + bonus) * buy_how_much
        ifelse inc < qbuy [user-message "You do not have enough money" stop] [
          ifelse qbuy > onfarm_inc[
            set offfarm_inc inc - qbuy
            set onfarm_inc 0
          ][set onfarm_inc onfarm_inc - qbuy]
        ]
      ]

      if biomass = "residue" or biomass = "manure" or biomass = "grain" or biomass = "conc"[
        set qbuy (2 + bonus2) * buy_how_much
        ifelse inc < qbuy [user-message "You do not have enough money" stop] [
          ifelse qbuy > onfarm_inc[
            set offfarm_inc inc - qbuy
            set onfarm_inc 0
          ][set onfarm_inc onfarm_inc - qbuy]
        ]
      ]

      if biomass = "poultry" [
        set qbuy (1 + bonus) * (buy_how_much / 10)
        ifelse inc < qbuy [user-message "You do not have enough money" stop] [
          ifelse qbuy > onfarm_inc[
            set offfarm_inc inc - qbuy
            set onfarm_inc 0
          ][set onfarm_inc onfarm_inc - qbuy]
        ]
      ]

      if biomass = "fertilizer" [
        set qbuy 1 * buy_how_much
        ifelse inc < qbuy [user-message "You do not have enough money" stop] [
          ifelse qbuy > onfarm_inc[
            set offfarm_inc inc - qbuy
            set onfarm_inc 0
          ][set onfarm_inc onfarm_inc - qbuy]
        ]
      ]

      ask one-of turtles with [typo = biomass][
        hatch buy_how_much[
          if biomass = "cattle" or biomass = "srum" or biomass = "donkey"[set state "skinny"]
          if biomass = "residue" [set shape "star" set hidden? true]
          if biomass = "conc" [set shape "lightning"]
          set farm item 0 [farm] of farmers with [player = gamer]
          if biomass != "poultry" and biomass != "fertilizer" and biomass != "conc"[set canmove "yes"
            move-to one-of patches with [(read-from-string plabel) = (item 0[pos] of farmers with [player = gamer])]]
          if biomass = "fertilizer" [set color 96];;used in sow
          if biomass = "manure" [set color 36
            move-to one-of turtles with [farm = item 0[farm] of farmers with [player = gamer] and shape = "triangle" ]]
          liens item 0 [farm] of farmers with [player = gamer]
        ]
      ]
    ]
  ][
    ask farmers with [player = gamer][
      let inc onfarm_inc + offfarm_inc
      set qbuy (6 + bonus3) * buy_how_much
      ifelse inc < qbuy [user-message "You do not have enough money" stop] [
        ifelse qbuy > onfarm_inc[
          set offfarm_inc inc - qbuy
          set onfarm_inc 0
        ][set onfarm_inc onfarm_inc - qbuy]
  ]
      ask one-of out-link-neighbors with [typo = biomass][
      hatch buy_how_much[
        set farm item 0 [farm] of farmers with [player = gamer]
        liens item 0 [farm] of farmers with [player = gamer]
      ]
    ]]
  ]
  ask patches with [plabel = "99"][set plabel ""]
end

to reproduce [gamer animal]
  ;;livestock reproduction, aging and dying
  let anima animal
  if anima = "wolf" [set anima "donkey"]
  ask farmers with [player = gamer][
    if day > 1 [
      ask out-link-neighbors with [shape = animal and canmove = "yes" and grazed != "yes"][
        set hunger hunger + 1
        set energy energy - 2

    ]]
  ask out-link-neighbors with [shape = animal and canmove = "yes"][
    if hunger >= 2 [
      set warn 1
        show (word gamer " you have a lost one or more "
          anima " in your herd!")
      die

    ]

      if energy <= 10 [set state "skinny"]
      if energy > 10 and energy <= 16 [set state "medium"]
      if energy > 16 [set state "fat" set energy 17]

    if energy > 14 and repro != "yes"[
     if random 101 >= 80 [
       hatch 1
        set repro "yes"
        set warn warn + 1
        show (word gamer " you have a "
          anima " newborn " " in your herd!");;20% of chance to reproduce
      ]
    ]
  ]
]
  liens "1" liens "2" liens "3" liens "4"
end

to feedfamily [gamer]
  ;;1 unit of grain = 2 persons for 12 months
  let nfeed 0
  let ration (item 0 [ngrain] of farmers with [player = gamer]) * 2
  ifelse (item 0 [feedfam] of farmers with [player = gamer]) = 0 [
  set nfeed item 0 [family_size] of farmers with [player = gamer]]
  [set nfeed item 0 [food_unsecure] of farmers with [player = gamer]]

    let foodreq ration - nfeed
  ask farmers with [player = gamer][
    ifelse foodreq < 0 [set food_unsecure abs foodreq set ngrain 0
      ask out-link-neighbors with [shape = "cylinder"][die]
    ]
    [set food_unsecure 0 set ngrain floor (ngrain - (nfeed / 2))
    ask n-of ceiling (nfeed / 2) out-link-neighbors with [shape = "cylinder"][die]
    ]
    set feedfam 1
]
end
@#$#@#$#@
GRAPHICS-WINDOW
456
10
864
419
-1
-1
30.8
1
10
1
1
1
0
0
0
1
0
12
-12
0
0
0
1
ticks
30.0

BUTTON
2
49
145
82
create game environment
environment
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
3
12
70
45
NIL
set-up
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
2
150
94
195
player1pos
player1pos
1 2 3 4
3

CHOOSER
2
206
94
251
player2pos
player2pos
1 2 3 4
2

CHOOSER
104
151
196
196
player3pos
player3pos
1 2 3 4
0

CHOOSER
104
207
196
252
player4pos
player4pos
1 2 3 4
1

TEXTBOX
28
99
145
139
Players position on the board
16
0.0
1

TEXTBOX
33
266
120
286
Player types
16
0.0
1

CHOOSER
4
294
96
339
player1type
player1type
"SOC" "SOL" "MOD" "LCL"
0

CHOOSER
101
295
193
340
player2type
player2type
"SOC" "SOL" "MOD" "LCL"
2

CHOOSER
4
345
96
390
player3type
player3type
"SOC" "SOL" "MOD" "LCL"
1

CHOOSER
101
345
193
390
player4type
player4type
"SOC" "SOL" "MOD" "LCL"
3

MONITOR
86
420
173
465
Month
month
17
1
11

TEXTBOX
923
10
1019
30
Player 1 stats
16
0.0
1

MONITOR
867
35
924
80
cattle
item 0 [ncow] of turtles with [player = \"player 1\" and shape = \"person farmer\"]
17
1
11

MONITOR
925
35
989
80
small rum
item 0 [nsrum] of turtles with [player = \"player 1\" and shape = \"person farmer\"]
17
1
11

MONITOR
990
35
1047
80
poultry
item 0 [npoultry] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1049
35
1099
80
donkey
item 0 [ndonkey] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1152
35
1202
80
fertilizer
item 0 [nfertilizer] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1204
35
1254
80
cart
item 0 [ncart] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1100
35
1150
80
tricycle
item 0 [ntricycle] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1257
35
1307
80
grain
item 0 [ngrain] of turtles with [\nplayer = \"player 1\" and\nshape = \"person farmer\"]
17
1
11

MONITOR
867
84
938
129
residue harv
item 0 [nresidue] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1111
85
1168
130
conc
item 0 [nconc] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1171
85
1228
130
manure
item 0 [nmanure] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1283
84
1333
129
on farm
item 0 [onfarm_inc] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1231
84
1282
129
off farm
item 0 [offfarm_inc] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

BUTTON
225
10
344
43
Grow crops and grass
grow [0]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
534
428
812
461
Next step
grow [0]\nharvest presid1 \"player 1\"\nharvest presid2 \"player 2\"\nharvest presid3 \"player 3\"\nharvest presid4 \"player 4\"\nfeedfamily \"player 1\"\nfeedfamily \"player 2\"\nfeedfamily \"player 3\"\nfeedfamily \"player 4\"\nset buy_how_much 0\nset sell_how_much 0\nset biomass_sent_amount 0\nset biomass_in_amount 0\nnextmonth
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
349
12
426
45
Harvest
harvest presid1 \"player 1\"\nharvest presid2 \"player 2\"\nharvest presid3 \"player 3\"\nharvest presid4 \"player 4\"\nuser-message \"Feed your family with the grain harvested before next step\"
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
231
93
323
126
presid1
presid1
0
100
49.0
1
1
NIL
HORIZONTAL

SLIDER
330
93
422
126
presid2
presid2
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
232
150
324
183
presid3
presid3
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
332
150
424
183
presid4
presid4
0
100
50.0
1
1
NIL
HORIZONTAL

TEXTBOX
222
52
426
70
Proportion of residue left on field
14
0.0
1

TEXTBOX
257
74
311
92
Player 1
12
0.0
1

TEXTBOX
353
73
399
91
Player 2
12
0.0
1

TEXTBOX
259
130
306
148
Player 3
12
0.0
1

TEXTBOX
352
130
396
148
Player 4
12
0.0
1

MONITOR
1019
85
1106
130
residue on field
count turtles\nwith [farm = \"1\" and\n hidden? = false and shape = \"star\"]
17
1
11

MONITOR
12
470
100
515
Season
saison
17
1
11

MONITOR
940
84
1014
129
stock residue
count turtles\nwith [farm = \"1\" and\n hidden? = true and shape = \"star\"]
17
1
11

TEXTBOX
925
131
1024
151
Player 2 stats
16
0.0
1

MONITOR
867
154
917
199
cattle
item 0 [ncow] of turtles with [player = \"player 2\" and shape = \"person farmer\"]
17
1
11

MONITOR
919
153
974
198
small rum
item 0 [nsrum] of turtles with [player = \"player 2\" and shape = \"person farmer\"]
17
1
11

MONITOR
976
153
1026
198
poultry
item 0 [npoultry] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1028
153
1078
198
donkey
item 0 [ndonkey] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1080
153
1130
198
tricycle
item 0 [ntricycle] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1132
153
1190
198
fertilizer
item 0 [nfertilizer] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1194
153
1246
198
cart
item 0 [ncart] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1250
152
1307
197
grain
item 0 [ngrain] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
868
201
942
246
residue harv
item 0 [nresidue] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
944
201
1019
246
stock residue
count turtles\nwith [farm = \"2\" and\n hidden? = true and shape = \"star\"]
17
1
11

MONITOR
1021
202
1107
247
residue on field
count turtles\nwith [farm = \"2\" and\n hidden? = false and shape = \"star\"]
17
1
11

MONITOR
1110
202
1160
247
conc
item 0 [nconc] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1163
202
1213
247
manure
item 0 [nmanure] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1215
202
1265
247
off farm
item 0 [offfarm_inc] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1269
201
1319
246
on farm
item 0 [onfarm_inc] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

TEXTBOX
931
252
1033
272
Player 3 stats
16
0.0
1

MONITOR
868
277
918
322
cattle
item 0 [ncow] of turtles with [player = \"player 3\" and shape = \"person farmer\"]
17
1
11

MONITOR
920
277
976
322
small rum
item 0 [nsrum] of turtles with [player = \"player 3\" and shape = \"person farmer\"]
17
1
11

MONITOR
979
277
1036
322
poultry
item 0 [npoultry] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1039
277
1089
322
donkey
item 0 [ndonkey] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1091
277
1141
322
tricycle
item 0 [ntricycle] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1143
277
1193
322
fertilizer
item 0 [nfertilizer] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1196
277
1246
322
cart
item 0 [ncart] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1249
277
1299
322
grain
item 0 [ngrain] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
868
324
939
369
residue harv
item 0 [nresidue] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
941
324
1017
369
stock residue
count turtles\nwith [farm = \"3\" and\n hidden? = true and shape = \"star\"]
17
1
11

MONITOR
1019
324
1103
369
residue on field
count turtles\nwith [farm = \"3\" and\n hidden? = false and shape = \"star\"]
17
1
11

MONITOR
1106
324
1156
369
conc
item 0 [nconc] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1159
324
1209
369
manure
item 0 [nmanure] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1212
325
1262
370
off farm
item 0 [offfarm_inc] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1264
324
1314
369
on farm
item 0 [onfarm_inc] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

TEXTBOX
933
376
1032
396
Player 4 stats
16
0.0
1

MONITOR
870
397
920
442
cattle
item 0 [ncow] of turtles with [player = \"player 4\" and shape = \"person farmer\"]
17
1
11

MONITOR
923
397
979
442
small rum
item 0 [nsrum] of turtles with [player = \"player 4\" and shape = \"person farmer\"]
17
1
11

MONITOR
982
397
1032
442
poultry
item 0 [npoultry] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1036
396
1086
441
donkey
item 0 [ndonkey] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1090
395
1140
440
tricycle
item 0 [ntricycle] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1143
395
1193
440
fertilizer
item 0 [nfertilizer] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1196
395
1246
440
cart
item 0 [ncart] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1248
395
1298
440
grain
item 0 [ngrain] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
870
445
942
490
residue harv
item 0 [nresidue] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
944
445
1020
490
stock residue
count turtles\nwith [farm = \"4\" and\n hidden? = true and shape = \"star\"]
17
1
11

MONITOR
1021
445
1109
490
residue on field
count turtles\nwith [farm = \"4\" and\n hidden? = false and shape = \"star\"]
17
1
11

MONITOR
1112
445
1162
490
conc
item 0 [nconc] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1166
445
1216
490
manure
item 0 [nmanure] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1219
445
1269
490
off farm
item 0 [offfarm_inc] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1272
446
1322
491
on farm
item 0 [onfarm_inc] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

TEXTBOX
274
193
389
233
Biomass fluxes between players
16
0.0
1

TEXTBOX
244
233
278
251
Send
14
0.0
1

TEXTBOX
367
236
419
254
Receive
14
0.0
1

CHOOSER
224
255
316
300
biomass_sender
biomass_sender
"player 1" "player 2" "player 3" "player 4"
0

CHOOSER
342
256
434
301
biomass_receiver
biomass_receiver
"player 1" "player 2" "player 3" "player 4"
3

CHOOSER
224
302
316
347
biomass_sent
biomass_sent
"residue" "manure" "grain" "concentrate" "cattle" "small ruminant" "donkey" "poultry" "money"
2

CHOOSER
341
303
451
348
biomass_counterpart
biomass_counterpart
"residue" "manure" "grain" "concentrate" "cattle" "small ruminant" "donkey" "poultry" "money"
0

INPUTBOX
210
349
328
409
biomass_sent_amount
0.0
1
0
Number

INPUTBOX
342
349
451
409
biomass_in_amount
0.0
1
0
Number

CHOOSER
134
528
226
573
buy
buy
"residue" "manure" "grain" "concentrate" "cattle" "small ruminant" "donkey" "poultry" "fertilizer" "cart" "tricyle"
0

CHOOSER
342
527
434
572
sell
sell
"residue" "manure" "grain" "concentrate" "cattle" "srum" "donkey" "poultry" "fertilizer" "cart" "tricyle"
1

INPUTBOX
230
531
317
591
buy_how_much
0.0
1
0
Number

INPUTBOX
437
529
526
589
sell_how_much
0.0
1
0
Number

TEXTBOX
303
461
360
481
Market
16
0.0
1

CHOOSER
225
481
317
526
buyer
buyer
"player 1" "player 2" "player 3" "player 4"
3

CHOOSER
342
480
434
525
seller
seller
"player 1" "player 2" "player 3" "player 4"
1

CHOOSER
580
487
672
532
feedconc_p1
feedconc_p1
"yes_1" "no_1"
0

CHOOSER
675
487
767
532
feedconc_p2
feedconc_p2
"yes_2" "no_2"
0

CHOOSER
580
534
672
579
feedconc_p3
feedconc_p3
"yes_3" "no_3"
0

CHOOSER
676
534
768
579
feedconc_p4
feedconc_p4
"yes_4" "no_4"
0

BUTTON
263
414
386
447
Apply biomass transfer
biomfluxes biomass_sender biomass_receiver biomass_sent biomass_counterpart
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
76
12
139
45
Sow
sow
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
446
486
516
519
Market
market-sell seller sell weight\nlivupdate seller\nmarket-buy buyer buy\nlivupdate buyer\nset buy_how_much 0\nset sell_how_much 0
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
108
471
170
516
Warning
warn
17
1
11

BUTTON
877
547
941
580
feed family
feedfamily family\n;livupdate family
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
861
496
953
541
family
family
"player 1" "player 2" "player 3" "player 4"
3

MONITOR
1013
528
1063
573
Player 1
item 0 [food_unsecure] of farmers with [player = \"player 1\"]
17
1
11

MONITOR
1071
528
1121
573
Player 2
item 0 [food_unsecure] of farmers with [player = \"player 2\"]
17
1
11

MONITOR
1128
527
1178
572
Player 3
item 0 [food_unsecure] of farmers with [player = \"player 3\"]
17
1
11

MONITOR
1183
527
1233
572
Player 4
item 0 [food_unsecure] of farmers with [player = \"player 4\"]
17
1
11

TEXTBOX
1067
501
1164
519
Food unsecure
14
0.0
1

CHOOSER
342
574
434
619
weight
weight
"skinny" "medium" "fat" 0
3

MONITOR
22
421
79
466
Year
year
17
1
11

MONITOR
1322
154
1387
199
risky cow
count turtles with [farm = \"2\" and\nhunger > 0 and shape = \"cow\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1322
36
1387
81
risky cow
count turtles with [farm = \"1\" and\nhunger > 0 and shape = \"cow\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1389
35
1459
80
risky srum
count turtles with [farm = \"1\" and\nhunger > 0 and shape = \"sheep\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1358
84
1441
129
risky donkey
count turtles with [farm = \"1\" and\nhunger > 0 and shape = \"wolf\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1388
153
1458
198
risky srum
count turtles with [farm = \"2\" and\nhunger > 0 and shape = \"sheep\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1344
202
1426
247
risky donkey
count turtles with [farm = \"2\" and\nhunger > 0 and shape = \"wolf\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1322
278
1387
323
risky cow
count turtles with [farm = \"3\" and\nhunger > 0 and shape = \"cow\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1386
278
1454
323
risky srum
count turtles with [farm = \"3\" and\nhunger > 0 and shape = \"sheep\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1352
326
1432
371
risky donkey
count turtles with [farm = \"3\" and\nhunger > 0 and shape = \"wolf\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1320
399
1385
444
risky cow
count turtles with [farm = \"4\" and\nhunger > 0 and shape = \"cow\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1387
398
1454
443
risky srum
count turtles with [farm = \"4\" and\nhunger > 0 and shape = \"sheep\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1354
447
1433
492
risky donkey
count turtles with [farm = \"4\" and\nhunger > 0 and shape = \"wolf\" and \n[pcolor] of patch-here != white\n]
17
1
11

BUTTON
157
75
220
108
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
152
109
224
142
NIL
startup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

acorn
false
0
Polygon -7500403 true true 146 297 120 285 105 270 75 225 60 180 60 150 75 105 225 105 240 150 240 180 225 225 195 270 180 285 155 297
Polygon -6459832 true false 121 15 136 58 94 53 68 65 46 90 46 105 75 115 234 117 256 105 256 90 239 68 209 57 157 59 136 8
Circle -16777216 false false 223 95 18
Circle -16777216 false false 219 77 18
Circle -16777216 false false 205 88 18
Line -16777216 false 214 68 223 71
Line -16777216 false 223 72 225 78
Line -16777216 false 212 88 207 82
Line -16777216 false 206 82 195 82
Line -16777216 false 197 114 201 107
Line -16777216 false 201 106 193 97
Line -16777216 false 198 66 189 60
Line -16777216 false 176 87 180 80
Line -16777216 false 157 105 161 98
Line -16777216 false 158 65 150 56
Line -16777216 false 180 79 172 70
Line -16777216 false 193 73 197 66
Line -16777216 false 237 82 252 84
Line -16777216 false 249 86 253 97
Line -16777216 false 240 104 252 96

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bird
false
0
Polygon -7500403 true true 135 165 90 270 120 300 180 300 210 270 165 165
Rectangle -7500403 true true 120 105 180 237
Polygon -7500403 true true 135 105 120 75 105 45 121 6 167 8 207 25 257 46 180 75 165 105
Circle -16777216 true false 128 21 42
Polygon -7500403 true true 163 116 194 92 212 86 230 86 250 90 265 98 279 111 290 126 296 143 298 158 298 166 296 183 286 204 272 219 259 227 235 240 241 223 250 207 251 192 245 180 232 168 216 162 200 162 186 166 175 173 171 180
Polygon -7500403 true true 137 116 106 92 88 86 70 86 50 90 35 98 21 111 10 126 4 143 2 158 2 166 4 183 14 204 28 219 41 227 65 240 59 223 50 207 49 192 55 180 68 168 84 162 100 162 114 166 125 173 129 180

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

checker piece 2
false
0
Circle -7500403 true true 60 60 180
Circle -16777216 false false 60 60 180
Circle -7500403 true true 75 45 180
Circle -16777216 false false 83 36 180
Circle -7500403 true true 105 15 180
Circle -16777216 false false 105 15 180

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

coin tails
false
0
Circle -7500403 true true 15 15 270
Circle -16777216 false false 20 17 260
Line -16777216 false 130 92 171 92
Line -16777216 false 123 79 177 79
Rectangle -7500403 true true 57 101 242 133
Rectangle -16777216 false false 45 180 255 195
Rectangle -16777216 false false 75 120 225 135
Polygon -16777216 false false 81 226 70 241 86 248 93 235 89 232 108 243 97 256 118 247 118 265 123 248 142 247 129 253 130 271 145 269 131 259 162 245 153 262 168 268 197 259 177 255 187 245 174 243 193 235 209 251 193 234 225 244 208 227 240 240 222 218
Rectangle -7500403 true true 91 210 222 226
Polygon -16777216 false false 65 70 91 50 136 35 181 35 226 65 246 86 241 65 196 50 166 35 121 50 91 50 61 95 54 80 61 65
Polygon -16777216 false false 90 135 60 135 60 180 90 180 90 135 120 135 120 180 150 180 150 135 180 135 180 180 210 180 210 135 240 135 240 180 210 180 210 135

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

drop
false
0
Circle -7500403 true true 73 133 152
Polygon -7500403 true true 219 181 205 152 185 120 174 95 163 64 156 37 149 7 147 166
Polygon -7500403 true true 79 182 95 152 115 120 126 95 137 64 144 37 150 6 154 165

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

lightning
false
0
Polygon -7500403 true true 120 135 90 195 135 195 105 300 225 165 180 165 210 105 165 105 195 0 75 135

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

molecule oxygen
true
0
Circle -7500403 true true 120 75 150
Circle -16777216 false false 120 75 150
Circle -7500403 true true 30 75 150
Circle -16777216 false false 30 75 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person farmer
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 60 195 90 210 114 154 120 195 180 195 187 157 210 210 240 195 195 90 165 90 150 105 150 150 135 90 105 90
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -13345367 true false 120 90 120 180 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 180 90 172 89 165 135 135 135 127 90
Polygon -6459832 true false 116 4 113 21 71 33 71 40 109 48 117 34 144 27 180 26 188 36 224 23 222 14 178 16 167 0
Line -16777216 false 225 90 270 90
Line -16777216 false 225 15 225 90
Line -16777216 false 270 15 270 90
Line -16777216 false 247 15 247 90
Rectangle -6459832 true false 240 90 255 300

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tile stones
false
0
Polygon -7500403 true true 0 240 45 195 75 180 90 165 90 135 45 120 0 135
Polygon -7500403 true true 300 240 285 210 270 180 270 150 300 135 300 225
Polygon -7500403 true true 225 300 240 270 270 255 285 255 300 285 300 300
Polygon -7500403 true true 0 285 30 300 0 300
Polygon -7500403 true true 225 0 210 15 210 30 255 60 285 45 300 30 300 0
Polygon -7500403 true true 0 30 30 0 0 0
Polygon -7500403 true true 15 30 75 0 180 0 195 30 225 60 210 90 135 60 45 60
Polygon -7500403 true true 0 105 30 105 75 120 105 105 90 75 45 75 0 60
Polygon -7500403 true true 300 60 240 75 255 105 285 120 300 105
Polygon -7500403 true true 120 75 120 105 105 135 105 165 165 150 240 150 255 135 240 105 210 105 180 90 150 75
Polygon -7500403 true true 75 300 135 285 195 300
Polygon -7500403 true true 30 285 75 285 120 270 150 270 150 210 90 195 60 210 15 255
Polygon -7500403 true true 180 285 240 255 255 225 255 195 240 165 195 165 150 165 135 195 165 210 165 255

tile water
false
0
Rectangle -7500403 true true -1 0 299 300
Polygon -1 true false 105 259 180 290 212 299 168 271 103 255 32 221 1 216 35 234
Polygon -1 true false 300 161 248 127 195 107 245 141 300 167
Polygon -1 true false 0 157 45 181 79 194 45 166 0 151
Polygon -1 true false 179 42 105 12 60 0 120 30 180 45 254 77 299 93 254 63
Polygon -1 true false 99 91 50 71 0 57 51 81 165 135
Polygon -1 true false 194 224 258 254 295 261 211 221 144 199

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
VIEW
366
24
766
424
0
0
0
1
1
1
1
1
0
1
1
1
0
12
-12
0

SLIDER
69
54
241
87
residue_on_field
residue_on_field
0.0
100.0
0
1.0
1
NIL
HORIZONTAL

CHOOSER
62
133
154
178
send_biomass
send_biomass
\"residue\" \"manure\" \"grain\" \"concentrate\" \"cattle\" \"small ruminant\" \"donkey\" \"poultry\" \"money\"
0

INPUTBOX
60
184
157
244
send_how_much
0.0
1
0
Number

CHOOSER
163
134
255
179
send_to
send_to
\"player 1\" \"player 2\" \"player 3\" \"player 4\"
0

BUTTON
166
195
260
228
transfer_biomass
NIL
NIL
1
T
OBSERVER
NIL
NIL

TEXTBOX
64
34
240
60
Proportion of residue to be left on field
10
0.0
1

TEXTBOX
120
109
270
127
Biomass transfer
11
0.0
1

CHOOSER
13
291
105
336
buy_what
buy_what
\"residue\" \"manure\" \"grain\" \"concentrate\" \"cattle\" \"small ruminant\" \"donkey\" \"poultry\" \"fertilizer\" \"cart\" \"tricyle\"
0

CHOOSER
107
291
199
336
who_buy
who_buy
\"player 1\" \"player 2\" \"player 3\" \"player 4\"
0

INPUTBOX
205
291
279
351
amount_buy
0.0
1
0
Number

CHOOSER
7
360
99
405
sell_what
sell_what
\"residue\" \"manure\" \"grain\" \"concentrate\" \"cattle\" \"small ruminant\" \"donkey\" \"poultry\" \"fertilizer\" \"cart\" \"tricyle\"
0

CHOOSER
110
360
202
405
who_sell
who_sell
\"player 1\" \"player 2\" \"player 3\" \"player 4\"
0

INPUTBOX
209
360
278
420
amount_sell
0.0
1
0
Number

BUTTON
121
456
191
489
Market
NIL
NIL
1
T
OBSERVER
NIL
NIL

TEXTBOX
134
273
284
291
Market
11
0.0
1

MONITOR
799
92
849
141
nplot
NIL
1
1

MONITOR
854
93
904
142
cattle
NIL
0
1

MONITOR
909
93
959
142
srum
NIL
0
1

MONITOR
1026
92
1083
141
poultry
NIL
0
1

MONITOR
964
93
1021
142
donkey
NIL
0
1

MONITOR
1090
92
1140
141
tricycle
NIL
0
1

MONITOR
1148
91
1198
140
fertilizer
NIL
0
1

MONITOR
1206
91
1256
140
cart
NIL
0
1

MONITOR
1264
91
1314
140
grain
NIL
0
1

MONITOR
800
153
872
202
residue harv
NIL
0
1

MONITOR
877
154
949
203
stock residue
NIL
0
1

MONITOR
956
155
1038
204
residue on field
NIL
0
1

MONITOR
1043
155
1100
204
conc
NIL
0
1

MONITOR
1105
155
1162
204
manure
NIL
0
1

MONITOR
1171
156
1229
205
off farm
NIL
3
1

MONITOR
1238
155
1295
204
on farm
NIL
0
1

MONITOR
930
221
994
270
risky cow
NIL
0
1

MONITOR
1002
221
1071
270
risky srum
NIL
0
1

MONITOR
1078
222
1147
271
risky donkey
NIL
0
1

MONITOR
1002
296
1079
345
food unsecure
NIL
3
1

BUTTON
1001
354
1084
387
feed family
NIL
NIL
1
T
OBSERVER
NIL
NIL

TEXTBOX
997
57
1082
77
Player stats
16
0.0
1

CHOOSER
111
408
203
453
biom_weight
biom_weight
\"skinny\" \"medium\" \"fat\" 0
0

MONITOR
5
565
396
614
warning
NIL
0
1

TEXTBOX
602
459
671
479
Message
16
0.0
1

INPUTBOX
477
495
701
630
message text
NIL
1
1
String

BUTTON
707
572
793
605
send message
NIL
NIL
1
T
OBSERVER
NIL
NIL

CHOOSER
704
500
796
545
message who
message who
\"player 1\" \"player 2\" \"player 3\" \"player 4\"
0

MONITOR
1041
627
1157
676
pseudo_
NIL
0
1

MONITOR
1177
627
1323
676
name
NIL
0
1

TEXTBOX
1158
599
1173
617
ID
11
0.0
1

@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
