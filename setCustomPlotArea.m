function setCustomPlotArea(handles,plotOpts,horSpace,vertSpace)
%
% Package NILM_CEPEL.GraphUtils: Function setCustomPlotArea
% Change subplot handles to occupy the specified usage area.
%
%                         ------  Inputs  -------
% 
% -> handles: The axes handles matrix. Each line correspond to a line
% at the figure plot, and the same for the columns.
%
% -> plotOpts: the PlotOpts handle containing the size to be occupied
% by the axes.
%
% -> horSpace: Contains the ammount of spaces that are occupied by
% the current subplot in the vertical distance.
%
% -> vertSpace: Contains the ammount of spaces that are occupied by
% the current subplot in the vertical distance.
%

% - Creation Date: Thu, 05 Sep 2013
% - Last Modified: Sun, 21 Aug 2016
% - Author(s): 
%   - W.S.Freund <wsfreund_at_gmail_dot_com>

  nHorHandles = size(handles,2);
  nVertHandles = size(handles,1);

  if nargin < 2
    plotOpts = Options.PlotOpts;
  end

  if nargin < 3 
    horSpace = ones(1,nHorHandles);
  elseif isempty(horSpace)
    horSpace = ones(1,nHorHandles);
  end

  if nargin < 4
    vertSpace  = ones(1,nVertHandles);
  elseif isempty(vertSpace)
    vertSpace  = ones(1,nVertHandles);
  end

  if numel(horSpace) ~= nHorHandles
    Output.ERROR('GraphUtils:setCustomPlotArea:WrongInput',...
      ['horSpace variable must have the same numel (%d) as the '...
      'handles columns (%d).'],numel(horSpace),nHorHandles);
  end

  if numel(vertSpace) ~= nVertHandles
    Output.ERROR('GraphUtils:setCustomPlotArea:WrongInput',...
      ['vertSpace variable must have the same numel (%d) as the '...
      'handles lines (%d).'],numel(vertSpace),nVertHandles);
  end

  nHorFig = sum(horSpace);
  nVertFig = sum(vertSpace);

  % Change plot positions:
  subplotWidth = plotOpts.widthUsableArea/nHorFig;
  subplotHeight = plotOpts.heigthUsableArea/nVertFig;

  totalWidth = plotOpts.rightBase - plotOpts.leftBase;
  totalHeight = plotOpts.topBase - plotOpts.bottomBase;

  gapHeigthSpace = (totalHeight - ... 
    plotOpts.heigthUsableArea)/(nVertFig);
  gapWidthSpace = (totalWidth - ... 
    plotOpts.widthUsableArea)/(nHorFig);

  botPos = plotOpts.bottomBase + gapHeigthSpace/2;
  leftPos = plotOpts.leftBase + gapWidthSpace/2;

  for curLine=nVertHandles:-1:1
    for curColumn=1:nHorHandles
      if ~(handles(curLine,curColumn)) || ~isempty(...
          strfind(class(handles(curLine,curColumn)),'root'))
        continue
      end
      set(handles(curLine,curColumn),'OuterPosition',[leftPos...
        botPos horSpace(curColumn)*subplotWidth ...
        vertSpace(curLine)*subplotHeight]);
      leftPos = leftPos + horSpace(curColumn)*subplotWidth + ...
        gapWidthSpace;
    end
    leftPos = plotOpts.leftBase + gapWidthSpace/2;
    botPos = botPos + vertSpace(curLine)*subplotHeight + ...
      gapHeigthSpace;
  end

end
