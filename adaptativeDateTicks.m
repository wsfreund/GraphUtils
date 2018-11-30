function adaptativeDateTicks(axesH,plotOpts,option,method)
%
% Package NILM_CEPEL.GraphUtils: Function adaptiveDateTicks
%   Set x axis to show date tick.
%
%   Set current axes to show date tick acording to axis limits. It
% will use axis handle in lowest handle in the column subplots to
% change the axis, removing the XTickLabel from the upper subplots.
%
%   GraphUtils.adaptiveDateTicks(axesH,plotOpts,option)
%
%                         ------  Inputs  -------
%
%   -> axesH (axes handles): the figure axis handles to change the
% axis display. They need to be arranged as a matrix as they are
% displayed on the screen.
%
%   -> plotOpts <Options.PlotOpts default object> (PlotOpts object):
%  The options used as fontSize and number of ticks.
%
%   -> option (boolean): whether to turn on or off the
%  adaptativeDateTicks.
%
%   -> method
%     o 'fullDate': show full date.
%     o 'distFromCenter': show time distance from center.
%


% - Creation Date: Thu, 05 Sep 2013
% - Last Modified: Mon, 16 Jul 2018
% - Author(s):
%   - W.S.Freund <wsfreund_at_gmail_dot_com>

if nargin < 4
  method = 'fullDate';
  if nargin<3
    option=true;
    if nargin<2
      plotOpts=Options.PlotOpts;
    end
  end
end

% Based on:
%
% http://undocumentedmatlab.com/blog/setting-axes-tick-labels-format/
%
% http://stackoverflow.com/questions/5448161/how-to-check-if-value-is-valid-property-in-matlab
%

[nLines,nColumns] = size(axesH);

fontSize = plotOpts.FontSize;
nTicks = plotOpts.nTicks;

if option
  for axesLine=nLines:-1:1
    for axesColumn=nColumns:-1:1
      curAxes = axesH(axesLine,axesColumn);
      if axesLine~=nLines
        if verLessThan('matlab','8.4.0')
          hhAxes = handle(curAxes);  % hAxes is the Matlab handle of our
          % axes
          hProp = findprop(hhAxes,'XLim');  % a schema.prop object
          xTickListener=handle.listener(hhAxes,hProp,'PropertyPostSet',...
            @(~,~)  changeXTicks(curAxes,nTicks));
          setappdata(curAxes,'xTickListener',xTickListener);
          changeXTicks(curAxes,nTicks);
        else
          xTickListener = addlistener(curAxes,'XLim','PostSet',...
            @(~,~) changeXTicks(curAxes,nTicks));
          changeXTicks(curAxes,nTicks);
          setappdata(curAxes,'xTickListener',xTickListener);
        end
      else
        if verLessThan('matlab','8.4.0')
          hhAxes = handle(curAxes);  % hAxes is the Matlab handle of our
          % axes
          hProp = findprop(hhAxes,'XLim');  % a schema.prop object
          switch method
          case 'fullDate'
            xTickListener=handle.listener(hhAxes,hProp,'PropertyPostSet',...
              @(~,~)  changeXLabelsAndTitle(curAxes,fontSize,nTicks));
          case 'distFromCenter'
            xTickListener=handle.listener(hhAxes,hProp,'PropertyPostSet',...
              @(~,~)  useAbsoluteLabels(curAxes,fontSize,nTicks));
          end
          setappdata(curAxes,'xTickListener',xTickListener);
          switch method
          case 'fullDate'
            changeXLabelsAndTitle(curAxes,fontSize,nTicks);
          case 'distFromCenter'
            useAbsoluteLabels(curAxes,fontSize,nTicks);
          end
        else
          switch method
          case 'fullDate'
            xTickListener = addlistener(curAxes,'XLim','PostSet',...
              @(~,~) changeXLabelsAndTitle(curAxes,fontSize,nTicks));
          case 'distFromCenter'
            xTickListener = addlistener(curAxes,'XLim','PostSet',...
              @(~,~) useAbsoluteLabels(curAxes,fontSize,nTicks));
          end
          switch method
          case 'fullDate'
            changeXLabelsAndTitle(curAxes,fontSize,nTicks);
          case 'distFromCenter'
            useAbsoluteLabels(curAxes,fontSize,nTicks);
          end
          setappdata(curAxes,'xTickListener',xTickListener);
        end
      end
    end
  end
else
  for axesLine=1:nLines
    for axesColumn=1:nColumns
      curAxes = axesH(axesLine,axesColumn);
      xTickListener=getappdata(curAxes,'xTickListener');
      if ~isempty(xTickListener)
        try
          delete(xTickListener);
        catch ext
          ext.identifier
          ext.getReport;
        end
      end
    end
  end
end
end

function changeXTicks(hAxes,nTicks)
  if GraphUtils.isMultipleCallback
    return
  end
  lim = xlim(hAxes);
  % Create the new format of the labels
  xTicks = linspace(lim(1),lim(2),nTicks);
  set(hAxes,'XTickMode','manual','XTick',xTicks,'XTickLabel',[]);
end

function useAbsoluteLabels(hAxes,fontSize,nTicks)
  if GraphUtils.isMultipleCallback
    return
  end
  lim = xlim(hAxes);
  % Create a linspace for the X new xticks:
  tDiff = lim(2)-lim(1);
  % Create the new format of the labels
  xTicks = linspace(lim(1),lim(2),nTicks);
  labels = cell(1,nTicks);
  for k = 1:nTicks
    switch sign(xTicks(k))
    case 1
      labels{k} = Utils.get_time(xTicks(k));
    case -1
      labels{k} = ['-' Utils.get_time(-xTicks(k))];
    case 0
      labels{k} = '000 ms';
    end
  end
  set(hAxes,'XTickMode','manual','XTickLabel',labels,...
    'XTick',xTicks);
end

function changeXLabelsAndTitle(hAxes,fontSize,nTicks)
  if GraphUtils.isMultipleCallback
    return
  end
  lim = xlim(hAxes);

  % Create a linspace for the X new xticks:
  tDiff = lim(2)-lim(1);
  % Create the new format of the labels
  xTicks = linspace(lim(1),lim(2),nTicks);
  % Create the new format of the labels
  if tDiff<(nTicks+1)/86400 % If elapsed time is lower than nTicks+1
    % seconds:
    nTicks = nTicks-2;
    if nTicks<2
      nTicks = 2;
    end
    xTicks = linspace(lim(1),lim(2),nTicks);
    labels = datestr(xTicks,'HH:MM:SS.FFF');
  elseif tDiff<(nTicks+1)/1440 % If elapsed time is lower than nTicks+1
    % minutes:
    labels = datestr(xTicks,'HH:MM:SS');
  elseif tDiff<1 % If elapsed time is lower than nTicks+1 days:
    labels = datestr(xTicks,'HH:MM');
  elseif tDiff<nTicks+1 % If elapsed time is lower than nTicks+1 days:
    labels = datestr(xTicks,'(dd) HH:MM');
  elseif tDiff<365 % If elapsed time is lower than one years:
    labels = datestr(xTicks,19);
  else % If time is greater than one years
    labels = datestr(xTicks,20);
  end
  set(hAxes,'FontSize',fontSize);
  %newLabels=datestr(tickValues,format)
  %set(hAxes, 'XTickLabel', newLabels)
  [rows,mumns]=size(labels);
  labels = mat2cell(labels,ones(1,rows),mumns);
  set(hAxes,'XTickMode','manual','XTickLabel',labels,'XTick',xTicks);
  % Check if there was a change in days, months or year in the
  % current axis:
  [yBegin, mBegin, dBegin] = datevec(lim(1));
  [yEnd, mEnd, dEnd] = datevec(lim(2));
  if yBegin~=yEnd || mBegin~=mEnd || dBegin~=dEnd
    xlabel(hAxes,sprintf('Date: from %s to %s.',datestr(...
      lim(1),1),datestr(lim(2),1)));
  else
    xlabel(hAxes,sprintf('Date: %s.',datestr((lim(2)+lim(1))/2,1)));
  end
end  % myCallbackFunction

