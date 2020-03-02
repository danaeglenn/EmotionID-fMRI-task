clear all; close all; clc;

includeTriggers=1;

% Lab filepath
rootPath='C:\Users\KIND Lab\Desktop\EmotionID\';

% Scanner filepath
%rootPath='C:\Users\CAN\KalinaM\EmotionID\';

cd(fullfile(rootPath,'Task'));
savepath=fullfile(rootPath,'Data');

% %%% Subject info prompt %%%
prompt = {'Subject ID:','Version:', 'Session:'}; %description of fields 
defaults = {'','','1'};%you can put in default responses - no defaults for now
SubInfo = inputdlg(prompt, 'Subject Info',1,defaults); %opens dialog box
SUBJECT = SubInfo{1,:}; %Gets Subject name from dialog box input
VersionEntered=SubInfo{2,:}; %Gets version number
if (VersionEntered~='1')&&(VersionEntered~='2')&&(VersionEntered~='3')&&(VersionEntered~='4')
        msgbox('Version must be between 1-4. Do not continue.');
    return
end 
c = clock; %Current date and time as date vector. [year month day hour minute seconds]
baseName=[SUBJECT '_EmoID_' num2str(c(2)) '_' num2str(c(3)) '_' num2str(c(4)) '_' num2str(c(5))]; %makes unique filename
matfile=fullfile(savepath,baseName);
%%
%%% Design matrix %%%

%randomizes seed
theseed=GetSecs;
rand('twister',theseed); 


% set design matrix: faceID, emotion, intensity
fID=4; %number of face identities
emoint= 15; % number of emotion intensities
emotype=2; %emotion type
matrand=[];
foo0 = [];
blockOrder(1,:)=[1 1 1 2 2 2];
blockOrder(2,:)=[2 2 2 1 1 1];
blockOrder(3,:)=[1 1 1 2 2 2];
blockOrder(4,:)=[2 2 2 1 1 1];

nblocks=6;
Version=str2num(VersionEntered);
nextKey=KbName('p');

triggerData=importdata('./Stimuli/BinaryToStimID.xlsx');
triggers=triggerData.data;

matrix=fullfact([fID emotype emoint]); %creates factorial design 
mat=matrix(5:end,:);%cuts out the duplicate happy faces

for i=1:nblocks
    
foo=[foo0 ; randperm(length(mat))' ]; %randomizes faceIDs and emotion intensities
matrand{i}=mat(foo,:);
responses{i}=zeros(length(matrand{i}),2)-1; %initialize response matrix with -1

end


Reminder{1}='You have %d minutes until the end of Part %d.';
Reminder{2}='You have %d minutes until you give your speech.';

timeReminder=[20 14 7 20 14 7];
ntrials=length(matrand{1});
%% %set durations

for block=1:6
fixDur(block,:)=(rand(length(responses{block}),1)*0+1)'; % fixation duration THIS IS WHERE YOU ADD JITTER - NONE NOW
cumfixDur(block,:)=zeros(length(fixDur)+1,1)'; 
cumfixDur(block,2:end)=cumsum(fixDur(block,:)); %cumulatively adds fixation durations and adds a 0 as the first value so cumulative times can be called
end
maskDur=.2; %mask duration
stimDur=.2; %stimulus duration
respDur=2; %response screen duration
instDur=2.5; %instructions duration (for instructions mid-task)
trialDur = respDur+stimDur+maskDur+.5; % task duration - does not include instructions or fixation
TargList=[2 3]; %list of button box response options

selects laptop or monitor depending on how many screens available
if Screen('Screens')==1
    if fmri == 0
        s=1;
    elseif fmri == 1
        s=0;
    end 
else 
    s=0;
end

%% %% Open Exp Screen %%%
% if fmri==0 % skips sync tests if on laptop
Screen('Preference', 'SkipSyncTests', 1)
% end 

[window, rect]=Screen('OpenWindow',s); %opens screen 
[width, height] = Screen('WindowSize',s); %gets dimensions of screen
HideCursor(); 
ListenChar(2);
slack = Screen('GetFlipInterval', window)/2; %creates slack to be subtracted from flip times 

%%% Load Stimuli %%%
% load face stimuli 
people{1} = {'10F' ,'18F', '37M', '42M'}; %face identities
people{2} = {'09F' ,'17F', '34M', '40M'}; 
emotions = {'AN', 'FE'}; %emotion
Emotion{1} = 'ANGRY'; 
Emotion{2} = 'AFRAID';

for run=1:2
for np =1:4 %for each face identity (4)
    for ne = 1:2 % for each emotion type (2)
        for morph = 1:15 %for each emotion morph (15)
            if morph <=9 %adds 0 into morph number when loading morphs 1-9
                str = './Stimuli/%s_HA_%s_0%d.tif';
            else 
                str = './Stimuli/%s_HA_%s_%d.tif';
            end 
            images{run}{np, ne, morph} = imread(sprintf(str, people{run}{np}, emotions{ne}, morph)); %loads face stimuli
            stim{run}(np, ne, morph) = Screen('MakeTexture', window, images{run}{np, ne, morph}); %creates textures for face stimuli
            
        end
    end
end
end

% load practice stim

for im=1:8
  str ='./Training/%d.tif';
pracimages{1,im}=imread(sprintf(str,im));
pracstim(1,im)=Screen('MakeTexture',window, pracimages{1, im});
end

% load mask  
maskImg = imread('Stimuli/mask.bmp'); %loads mask stimuli
maskTex = Screen('MakeTexture', window, maskImg); %creates mask texture

% load instructions arrows
arrowImg = imread('Stimuli/arrow.bmp');
arrowTex = Screen('MakeTexture', window, arrowImg); %creates arrow texture

%%% Set keypress
KbName('UnifyKeyNames'); % cross-platform compatibility of keynaming
spaceKey=(KbName('space')); 
hKey=KbName('UpArrow'); 
fKey=KbName('RightArrow');
aKey=KbName('LeftArrow');
sKey=KbName('DownArrow');
KeyList=[aKey fKey hKey sKey];
KbQueueCreate; %creates key response cue
KbQueueStart;  %starts cue

%%% Turn on DataPixx
if fmri == 1
    %%% Datapixx on
Datapixx('Open'); %opens Datapixx
Datapixx('StopAllSchedules'); %Stop running all DAC/ADC/DOUT/DIN/AUD/AUX/MIC schedules
Datapixx('RegWrRd'); %checks in with datapixx
end 

%text dimensions
xleft=width*.35;
xright=width*.65;
xcenter=width*.5;
ytop=height*.3;
ybottom=height*.7;
ycenter=height*.5;

lengthFear=117; 
lengthAnger=113;
lengthHappy=107;
lengthSad=65;

% Set up biopac triggers
if includeTriggers==1
ioObj = io64; %create an instance of the io64 object
status = io64(ioObj); % initialize the interface to the inpoutx64 system driver
% if status = 0, you are now ready to write and read to a hardware port
address = hex2dec('DFF8'); % LPT1 output port address

% Start trigger
data_out(8)=triggers(8,1); 
io64(ioObj,address,data_out(8)); %trigger on
io64(ioObj,address,0);% trigger off
end 

%%% Instructions 1 %%%
Screen('TextFont',window, 'Arial'); %instructions font, text size, formatting
Screen('TextSize',window, 32); 
Screen('TextStyle', window, 0); 
DrawFormattedText(window,'In this task, a face will appear and then quickly disappear.','center',height*.3,[0 0 0]);
DrawFormattedText(window,'Press the arrows to select whether the face was HAPPY, ANGRY, AFRAID, or SAD.','center',height*.37,[0 0 0]);
if fmri==0 %changes instructions based on whether this is behavioral or in scanner
    Screen('DrawTexture', window, arrowTex, [], [width/2-122 height*.6-101 width/2+122 height*.6+101]);%%THIS NEEDS FIXING
[~, ~, textBoundsA]=DrawFormattedText(window,'ANGRY',xleft-lengthAnger/2,height*.65,[0 0 0]);
[~, ~, textBoundsF]=DrawFormattedText(window,'AFRAID',xright-lengthFear/2,height*.65,[0 0 0]);
[~, ~, textBoundsH]=DrawFormattedText(window,'HAPPY',xcenter-lengthHappy/2,height*.5,[0 0 0]);
[~, ~, textBoundsS]=DrawFormattedText(window,'SAD',xcenter-lengthSad/2,height*.75,[0 0 0]);

elseif fmri ==1
DrawFormattedText(window,'If the face was happy, press the "HAPPY" button with your POINTER FINGER.','center',height*.5,[0 0 0]);
DrawFormattedText(window,'If the face was angry or afraid, press the "ANGRY/AFRAID" button with your MIDDLE FINGER.','center',height*.57,[0 0 0]);
end 

if includeTriggers==1
data_out(7)=triggers(7,1); 
io64(ioObj,address,data_out(7)); %trigger on
end 

Screen('Flip',window); % flips to instructions 1 presentation
WaitSecs(1); % participant sees instructions X secs before can flip
KbQueueWait(); % waits for response before continuing 
triggerPTime = -1; % sets trigger time as -1 in case not using scanner

%Instructions 2
Screen('TextFont',window, 'Arial'); %instructions font, text size, formatting
Screen('TextSize',window, 40); 
Screen('TextStyle', window, 0); 
DrawFormattedText(window,'Let''s practice!','center',height*.3,[0 0 0]);
DrawFormattedText(window,'Press any key to continue','center',height*.6,[0 0 0]);
Screen('Flip',window); % flips to instructions presentation
KbQueueWait(); % waits for response before continuing 

if includeTriggers==1
io64(ioObj,address,0);% trigger off
end 


%%% Practice trials
for practrial =1:8
    
Screen('TextSize',window, 80);
Screen('TextStyle', window, 0);
DrawFormattedText(window,'+','center','center',[0 0 0]);
fixonP(practrial) = Screen('Flip',window);
% fixation time uses absolute time from the RunStartTime - all other stimuli are timed relative to trial's fixation onset

%%% Face stimulus - draws face stimulus
Screen('DrawTexture', window, pracstim(1,practrial), []);
stimonP(practrial) = Screen('Flip',window, fixonP(practrial)+fixDur(1)); 
stimoffP(practrial) = Screen('Flip',window, fixonP(practrial)+stimDur+fixDur(1)); 
%sets flips relative to fixation onset

%%% Mask - draws mask texture
Screen('DrawTexture', window, maskTex, []);
maskonP(practrial) = Screen('Flip',window);
maskoffP(practrial) = Screen('Flip',window, maskDur+fixonP(practrial)+stimDur+fixDur(1));

KbQueueFlush; %Flushes Buffer so accidental keypresses aren't marked as a response

% Text dimensions
xleft=width*.35;
xright=width*.65;
xcenter=width*.5;
ytop=height*.3;
ybottom=height*.7;
ycenter=height*.5;

lengthFear=186;
lengthAnger=177;
lengthHappy=164;
lengthSad=100;

%%% Response Screen
Screen('TextSize',window, 50);
Screen('TextStyle', window, 0);
DrawFormattedText(window,'?',xcenter,ycenter,[0 0 0]);
[~, ~, textBoundsA2]=DrawFormattedText(window,'ANGRY',xleft-lengthAnger/2,ycenter,[0 0 0]);
[~, ~, textBoundsF2]=DrawFormattedText(window,'AFRAID',xright-lengthFear/2,ycenter,[0 0 0]);
[~, ~, textBoundsH2]=DrawFormattedText(window,'HAPPY',xcenter-lengthHappy/2,ytop,[0 0 0]);
[~, ~, textBoundsS2]=DrawFormattedText(window,'SAD',xcenter-lengthSad/2,ybottom,[0 0 0]);
starttimeP(practrial) = Screen('Flip',window);

keyIndex = -1; % sets no response to -1
endtimeP(practrial) = -1; % sets reaction time for no response to -1

% if fmri == 0
TheKeysP(practrial)=-1; %sets response to -1 if no keypress

keypressed=0;
while GetSecs < (starttimeP(practrial)+respDur) && keypressed==0 
    %before time limit expires and while button not checked
    [pressed, firstPress]=KbQueueCheck();%check for button press
    
    if (pressed)
    firstPress(find(firstPress==0))=NaN; %find key index
    [endtime(practrial), keyVal]=min(firstPress);
    if any(keyVal==KeyList)
TheKeysP(1,practrial)=find(keyVal==KeyList); %looks for which Key was pressed
Screen('TextSize',window, 50);
Screen('TextStyle', window, 0);
DrawFormattedText(window,'ANGRY',xleft-lengthAnger/2,ycenter,[0 0 0]);
DrawFormattedText(window,'AFRAID',xright-lengthFear/2,ycenter,[0 0 0]);
DrawFormattedText(window,'HAPPY',xcenter-lengthHappy/2,ytop,[0 0 0]);
DrawFormattedText(window,'SAD',xcenter-lengthSad/2,ybottom,[0 0 0]);

penWidth=6;

if keyVal==KeyList(1)
    Screen('FrameRect', window, [127], [xleft-lengthAnger/2-20 ycenter-50 xleft+lengthAnger/2+20 ycenter+20], penWidth) %Anger
elseif keyVal==KeyList(2)
    Screen('FrameRect', window, [127], [xright-lengthFear/2-20 ycenter-50 xright+lengthFear/2+20 ycenter+20], penWidth) %Fear
elseif keyVal==KeyList(3)
    Screen('FrameRect', window, [127], [xcenter-lengthHappy/2-20 ytop-50 xcenter+lengthHappy/2+20 ytop+20], penWidth) %Happy
elseif keyVal==KeyList(4)
    Screen('FrameRect', window, [127], [xcenter-lengthSad/2-20 ybottom-50 xcenter+lengthSad/2+20 ybottom+20], penWidth) %Sad
end 
    end 
        keypressed=1;  % if key is pressed, flip to blank screen
        respoffP = Screen('Flip',window); 
        WaitSecs(1)

    end
end     
end 
if includeTriggers==1
io64(ioObj,address,0); %trigger off
end 
if fmri ==1
%%% Draw trigger screen %%%
% Screen('TextFont',window, 'Arial');
Screen('TextSize',window, 35);
Screen('TextStyle', window, 0);
DrawFormattedText(window,'Please wait for experiment to begin.','center','center',[0 0 0]);


%%% align clocks to trigger
Datapixx('RegWrVideoSync'); %synchronize register writes to flip
triggerPTime = Screen('Flip', window); %computer trigger time 
triggerDTime = Datapixx('GetTime'); %datapixx trigger time at flip

[Bpress triggerDtime RespTime ] = SimpleWFE(10000, 11); %
RunStartTime = triggerDtime + RespTime; %sets start time for fmri task 

% else 
RunStartTime=GetSecs; % sets start time for behavioral task
% end  


%%%%%%% Experiment loop %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Instructions 
for block=1:nblocks
   if block<4
       run=1;
   elseif block>=4
       run=2;
   end 
   
    if includeTriggers==1 
data_out(7)=triggers(7,1); 
io64(ioObj,address,data_out(7)); % instructions trigger on   
    end 

   if block==1||block==4
Screen('TextFont',window, 'Arial'); %instructions font, text size, formatting
Screen('TextSize',window, 32); 
Screen('TextStyle', window, 0); 
DrawFormattedText(window,'Now please begin the task.','center',height*.3,[0 0 0]);
DrawFormattedText(window,'Remember, press the arrow keys to select whether the face was HAPPY, ANGRY, AFRAID, or SAD.','center',height*.38,[0 0 0]);
DrawFormattedText(window,'Please answer as quickly and as accurately as possible.','center',height*.46,[0 0 0]);

DrawFormattedText(window,'Press any key to begin the experiment.','center',height*.6,[0 0 0]);
Screen('Flip',window); % flips to instructions presentation
KbQueueWait(); % waits for response before continuing 

if includeTriggers==1
io64(ioObj,address,0); %instructions trigger off
end 
   end 
for trial = 1:5

    if trial==1 %triggers next block every 120 trials
Screen('TextFont',window, 'Arial'); %instructions font, text size, formatting
Screen('TextSize',window, 50); 
Screen('TextStyle', window, 1);
if Version < 2
    DrawFormattedText(window,sprintf(Reminder{run},timeReminder(block)),'center','center',[255 0 0]);
else
    DrawFormattedText(window,sprintf(Reminder{1},timeReminder(block),run),'center','center',[255 0 0]);
end 

blockon(run)=Screen('Flip',window); % flips to instructions presentation
WaitSecs(3)
    end
    
    
if includeTriggers==1
    if trial==1 %triggers next block every 120 trials
    data_out(triggers(blockOrder(Version,block),1))= triggers(blockOrder(Version,block),1);
    io64(ioObj,address, data_out(triggers(blockOrder(Version,block),1))); % block trigger on  
    end 
end 

%%% Fixation - draws fixation (includes jitter)
% Screen('TextFont',window, 'Times New Roman');
Screen('TextSize',window, 80);
Screen('TextStyle', window, 0);
DrawFormattedText(window,'+','center','center',[0 0 0]);
fixon(block,trial) = Screen('Flip',window, RunStartTime+trialDur*(trial-1)+cumfixDur(trial) + instDur*(floor(trial/6)+1));

%%% Face stimulus - draws face stimulus
Screen('DrawTexture', window, stim{run}(matrand{block}(trial,1),matrand{block}(trial,2),matrand{block}(trial,3)), []);
stimon(block,trial) = Screen('Flip',window, fixon(block,trial)+fixDur(block,trial)-slack); 
stimoff(block,trial) = Screen('Flip',window, fixon(block,trial)+fixDur(block,trial)+stimDur-slack); 
%sets flips relative to fixation onset

%%% Mask - draws mask texture
Screen('DrawTexture', window, maskTex, []);
maskon(block,trial) = Screen('Flip',window);
maskoff(block,trial) = Screen('Flip',window, fixon(block,trial)+fixDur(block,trial)+stimDur+maskDur-slack);

KbQueueFlush; %Flushes Buffer so accidental keypresses aren't marked as a response

%text dimensions
xleft=width*.35;
xright=width*.65;
xcenter=width*.5;
ytop=height*.3;
ybottom=height*.7;
ycenter=height*.5;

lengthFear=186;
lengthAnger=177;
lengthHappy=164;
lengthSad=100;

%%% Response Screen
Screen('TextSize',window, 50);
Screen('TextStyle', window, 0);
DrawFormattedText(window,'?',xcenter,ycenter,[0 0 0]);
[~, ~, textBoundsA2]=DrawFormattedText(window,'ANGRY',xleft-lengthAnger/2,ycenter,[0 0 0]);
[~, ~, textBoundsF2]=DrawFormattedText(window,'AFRAID',xright-lengthFear/2,ycenter,[0 0 0]);
[~, ~, textBoundsH2]=DrawFormattedText(window,'HAPPY',xcenter-lengthHappy/2,ytop,[0 0 0]);
[~, ~, textBoundsS2]=DrawFormattedText(window,'SAD',xcenter-lengthSad/2,ybottom,[0 0 0]);
starttime(block,trial) = Screen('Flip',window);

keyIndex = -1; % sets no response to -1
endtime(block,trial) = -1; % sets reaction time for no response to -1
% if fmri == 0
TheKeys(block,trial)=-1; %sets response to -1 if no keypress

keypressed=0;
while GetSecs < (starttime(block,trial)+respDur) && keypressed==0 
    %before time limit expires and while button not checked
    [pressed, firstPress]=KbQueueCheck();%check for button press
    
    if (pressed)
    firstPress(find(firstPress==0))=NaN; %find key index
    [endtime(block,trial), keyVal]=min(firstPress);
    if any(keyVal==KeyList)
TheKeys(1,trial)=find(keyVal==KeyList); %looks for which Key was pressed
Screen('TextSize',window, 50);
Screen('TextStyle', window, 0);
DrawFormattedText(window,'ANGRY',xleft-lengthAnger/2,ycenter,[0 0 0]);
DrawFormattedText(window,'AFRAID',xright-lengthFear/2,ycenter,[0 0 0]);
DrawFormattedText(window,'HAPPY',xcenter-lengthHappy/2,ytop,[0 0 0]);
DrawFormattedText(window,'SAD',xcenter-lengthSad/2,ybottom,[0 0 0]);

penWidth=6;

if keyVal==KeyList(1)
    Screen('FrameRect', window, [127], [xleft-lengthAnger/2-20 ycenter-50 xleft+lengthAnger/2+20 ycenter+20], penWidth) %Anger
elseif keyVal==KeyList(2)
    Screen('FrameRect', window, [127], [xright-lengthFear/2-20 ycenter-50 xright+lengthFear/2+20 ycenter+20], penWidth) %Fear
elseif keyVal==KeyList(3)
    Screen('FrameRect', window, [127], [xcenter-lengthHappy/2-20 ytop-50 xcenter+lengthHappy/2+20 ytop+20], penWidth) %Happy
elseif keyVal==KeyList(4)
    Screen('FrameRect', window, [127], [xcenter-lengthSad/2-20 ybottom-50 xcenter+lengthSad/2+20 ybottom+20], penWidth) %Sad
end 
    end 
        keypressed=1;  % if key is pressed, flip to blank screen
        respoff = Screen('Flip',window); 

    end
end 

    responses{block}(trial,1)=TheKeys(block,trial); %records response key
    if endtime(block,trial) == -1 %if no response, set time and response to -1
        responses{block}(trial,2) = endtime(block,trial);
    else 
    responses{block}(trial,2)=endtime(block,trial)-starttime(block,trial); %records response time
    end 
   

%flips after response duration has passed
respoff(block,trial)=Screen('Flip',window, fixon(block,trial)+fixDur(block,trial)+stimDur+maskDur+respDur-slack); 

if includeTriggers==1
if rem((trial)/120,1)==0 %turns off block trigger
io64(ioObj,address,0); % block trigger off  
end 
end 

save(baseName, 'responses')
end 
if block==3 || block==6
Instructions1=sprintf('You are done with Part %d',run);
Instructions2='Please ring the bell so the experimenter can give you the next instructions.';

% Pause/finish instructions
Screen('TextFont',window, 'Arial');
Screen('TextSize',window, 40);
Screen('TextStyle', window, 0);
DrawFormattedText(window,Instructions1,'center',height*.4,[0 0 0]);
DrawFormattedText(window,Instructions2,'center',height*.6,[0 0 0]);
Screen('Flip',window);

if includeTriggers==1
data_out(5)=triggers(5,1); 
io64(ioObj,address,data_out(5)); %trigger on
end 

if run==1
    nextpressed=0;
    while (nextpressed==0)
        [ pressed, firstPress]=KbQueueCheck; %checks for keys
        nextpressed=firstPress(nextKey);
    if (pressed && nextpressed)
            Screen('Flip',window);
    end    
    end
end 
else 
            
WaitSecs(3)
finaltime(block)=Screen('Flip',window); %records final flip time
end 
end 
 

if fmri == 1
finalDtime = Datapixx('GetTime'); %datapixx trigger time
Datapixx('StopDinLog'); % turns off logging
Datapixx('Close');
end 

ListenChar(0); %regain ability to type
ShowCursor(); %show cursor

save(matfile) % saves everything in the workspace
 
sca %close screen


