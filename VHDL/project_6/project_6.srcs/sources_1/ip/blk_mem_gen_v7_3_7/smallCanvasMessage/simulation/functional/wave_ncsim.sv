

 
 
 

 



window new WaveWindow  -name  "Waves for BMG Example Design"
waveform  using  "Waves for BMG Example Design"

      waveform add -signals /smallCanvasMessage_tb/status
      waveform add -signals /smallCanvasMessage_tb/smallCanvasMessage_synth_inst/bmg_port/CLKA
      waveform add -signals /smallCanvasMessage_tb/smallCanvasMessage_synth_inst/bmg_port/ADDRA
      waveform add -signals /smallCanvasMessage_tb/smallCanvasMessage_synth_inst/bmg_port/DOUTA

console submit -using simulator -wait no "run"
