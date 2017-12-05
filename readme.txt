### INSTALL ###

Please install the following perl modules before running the program.

DBI
Getopt::Long
Tree::Binary2
SVG

Also the sqlite should be installed first if in the Linux/Mac. In Windows, it doesn't need to install sqlite, because the sqlite.exe has been put in this directory.



### RUN PROGRAMS ###

1. Put all CDfiles .csv files into the data/ folder.


2. Run the Import2db_sqlite.pl program to store all .csv files into the database.

It will take few minutes and automatically generate a database file (*.db3) in the data/ folder. If you add more .csv files into the data/ folder, please run the Import2db_sqlite.pl porgram after the addition. Once the database file has been generated, the Draw_cell_lineage_tree_overlapping.pl program can access the data from it.


3. Run the Draw_cell_lineage_tree_overlapping.pl program to draw lineaging tree.
   
There are several options to set the tree. For examples,

To draw a single tree with one .csv file:
$ perl Draw_cell_lineage_tree_overlapping.pl CD130826PHA4p2 --root P0 --cellstage 350 --label --bottomlabel --axis --brand

To draw a merged tree with two .csv file:
$ perl Draw_cell_lineage_tree_overlapping.pl CD130826PHA4p2 CD140102NHR25p2 --root P0 --cellstage 350 --label --bottomlabel --axis --brand --mixtree


To set the root of tree, please use the option: --root ABara

To set the cell stage, please use the option: --cellstage 350

To set the end timepoint, please use the option: --endtime 300

To show cell name, please use the option: --label --bottomlabel

To draw two .csv files in a tree in side-by-side way, please use the option: --nomixtree

To show the axis and the brand, please use the option: --axis --brand

To draw an autozoom tree which means the tree can be resized with the window size, please use the option: --autozoom

To draw a binary expression tree with a specific cutoff, please use the option: --cutoff 1500 -b

To draw a model tree, please use the option: -m

To set the gap between two vertical lines on the tree, please use the option: --lineinter 15

To set the width of the line on the tree, please use the option: --linewidth 5

Please run:
$ perl Draw_cell_lineage_tree_overlapping.pl -h

to see more details of the usage.


4. The result of the drawing is formatted as a .svg file in the results/ folder.


At this moment, the following commands are used to get the results in the results/ folder.

CD130826PHA4p2_CD140102NHR25p2_P0_tp140_c364.svg
$ perl Draw_cell_lineage_tree_overlapping.pl CD130826PHA4p2 CD140102NHR25p2 --label --bottomlabel --axis --brand --mixtree

CD160912cdt1p1_CD170818cyb1p1_P0_tp154_c398.svg
$ perl Draw_cell_lineage_tree_overlapping.pl CD160912cdt1p1 CD170818cyb1p1 --cellstage 400 --label --bottomlabel --axis --brand --mixtree

CD161019cdt1pat3ip1_CD170822cyb1pat3ip3_P0_tp158_c399.svg
$ perl Draw_cell_lineage_tree_overlapping.pl CD161019cdt1pat3ip1 CD170822cyb1pat3ip3 --cellstage 400 --label --bottomlabel --axis --brand --mixtree

CD161019cdt1pat3ip1_CD170822cyb1pat3ip3_ABplapap_tp350_c1455.svg
$ perl Draw_cell_lineage_tree_overlapping.pl CD161019cdt1pat3ip1 CD170822cyb1pat3ip3 --root ABplapap --endtime 350 --label --bottomlabel --axis --brand --mixtree --lineinter 100 --linewidth 10 --scale 3 --titlefontsize 8

CD161019cdt1pat3ip1_CD170822cyb1pat3ip3_ABprapap_tp350_c1455.svg
$ perl Draw_cell_lineage_tree_overlapping.pl CD161019cdt1pat3ip1 CD170822cyb1pat3ip3 --root ABprapap --endtime 350 --label --bottomlabel --axis --brand --mixtree --lineinter 100 --linewidth 10 --scale 3 --titlefontsize 8














