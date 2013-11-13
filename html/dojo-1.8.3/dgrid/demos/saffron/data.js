define(["dojo/store/Memory", "dojo/store/Observable"], function(Memory, Observable){
	//	create some song data, and return a Memory Store from it.
	var data = {
		identifier: "Key",
		label: "project",
		items: [
			{"Key":1,"project":"23andMe","sample":"LP6005115-DNA_A01","lane":"C16VNACXX_6"},
			{"Key":1,"project":"23andMe","sample":"LP6005115-DNA_B01","lane":"C16VNACXX_7"},
			{"Key":1,"project":"23andMe","sample":"LP6005115-DNA_B01","lane":"C16VNACXX_8"},
			{"Key":2,"project":"23andMe2","sample":"LP6005206-DNA_F12","lane":"D1JPWACXX_1"},
			{"Key":3,"project":"23andMe_Wojcicki_2","sample":"SS6005002","lane":"D0JJVACXX"}
		]
	};

	// global var "song_store"
	songStore = Observable(Memory({data: data}));
	console.log("songStore:");
	console.dir({songStore:songStore});
	
	return songStore;
});


			//{"Key":1,"project":"23andMe","total":"818","lane":"0","delivered":"818","otherstate":"0","activesamples":"0","building":"0","readytoqc":"-3","touched":"818"},
			//{"Key":2,"project":"23andMe2","total":"279","lane":"1","delivered":"268","otherstate":"10","activesamples":"0","building":"0","readytoqc":"9","touched":"278"},
			//{"Key":3,"project":"23andMe_Wojcicki_2","total":"4","lane":"0","delivered":"4","otherstate":"0","activesamples":"0","building":"0","readytoqc":"-4","touched":"4"},
			//{"Key":4,"project":"23andMe_Wojicki","total":"0","lane":"0","delivered":"0","otherstate":"0","activesamples":"0","building":"0","readytoqc":"0","touched":"0"},
			//{"Key":5,"project":"Amgen_Misura","total":"0","lane":"0","delivered":"0","otherstate":"0","activesamples":"0","building":"0","readytoqc":"0","touched":"0"},
			//{"Key":6,"project":"Ancestry_Ball","total":"3","lane":"0","delivered":"3","otherstate":"0","activesamples":"0","building":"0","readytoqc":"0","touched":"3"},
			//{"Key":7,"project":"BartsLG_vanHeel","total":"1","lane":"0","delivered":"1","otherstate":"0","activesamples":"0","building":"0","readytoqc":"-1","touched":"1"},
			//{"Key":8,"project":"BU_Baldwin","total":"14","lane":"0","delivered":"14","otherstate":"0","activesamples":"0","building":"0","readytoqc":"0","touched":"14"},
			//{"Key":9,"project":"CaseWestern_Scacheri","total":"9","lane":"3","delivered":"6","otherstate":"0","activesamples":"0","building":"0","readytoqc":"0","touched":"6"},
			//{"Key":10,"project":"CCG_Thomas","total":"113","lane":"4","delivered":"106","otherstate":"3","activesamples":"0","building":"0","readytoqc":"1","touched":"109"},
			//{"Key":11,"project":"CCG_Thomas2","total":"50","lane":"0","delivered":"40","otherstate":"10","activesamples":"0","building":"1","readytoqc":"9","touched":"50"}

// SAMPLE Per Lane Details
//			date_started	fc barcode	fc status	lane	lane status	align status	 yield trimmed gb	yield Aligned gb	lib insert median; low;high	align per r1r2	error rate r1r2	per good tiles	per Q30 r1r2	Change Status	Comments
//2012-08-21	C16VNACXX	run finished	6	bioinfo threshold	2012-08-27 alignment complete	8.04	7.1	263; (46:53)	88.86; 88.32	0.59; 0.75	15.62	84.22; 75.07		
//2012-08-21	C16VNACXX	run finished	7	lane qc pass	2012-08-27 alignment complete	15.91	14.1	263; (46:53)	88.89; 88.26	0.59; 0.80	31.25	87.85; 83.06		
//2012-08-21	C16VNACXX	run finished	8	lane qc pass	2012-08-27 alignment complete	31.98	28.3	263; (47:53)	88.88; 88.27	0.58; 0.79	62.50	87.93; 81.52		
//2012-09-01	D1CRRACXX	run finished	5	lane qc pass	2012-09-07 alignment complete	62.52	55.1	263; (47:53)	88.50; 87.65	0.84; 1.18	100.00	82.12; 76.60		
//2012-09-01	D1CRRACXX	run finished	6	lane qc pass	2012-09-07 alignment complete	62.77	55.2	263; (47:53)	88.47; 87.55	0.85; 1.21	100.00	82.10; 76.42		