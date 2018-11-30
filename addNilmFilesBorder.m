function textH = addNilmFilesBorder(handles,fileStartStamps,...
  fileEndStamps)
%
% Package NILM_CEPEL.GraphUtils: Function addNilmFilesBorder
%   Draw lines at the start and end of files together with the files
% names.
%
%                         ------  Inputs  -------
%
% -> handles: The axes handles matrix. Each line correspond to a line
% at the figure plot, and the same for the columns.
%
% -> fileStartStamps: Stamps which mark files start.
%
% -> fileEndStamps: Stamps which mark files end.
%

% - Creation Date: Thu, 05 Sep 2013
% - Last Modified: Mon, 16 Jul 2018
% - Author(s):
%   - W.S.Freund <wsfreund_at_gmail_dot_com>

  nPlots = size(handles,1);
  nPhases = size(handles,2);


  nFiles = numel(fileStartStamps);

  startFileBorder = zeros(nPlots,nPhases,nFiles);
  endFileBorder = zeros(nPlots,nPhases,nFiles);

  figH = ancestor(handles(1),'figure');

  for k = 1:nPlots
    for m = 1:nPhases
      textH = zeros(2,nFiles);
      set(figH,'CurrentAxes',handles(k,m))
      for curFile = 1:nFiles
        yl = ylim(handles(k,m));
        if yl(1)>0
          yl(1) = 0;
        end
        startFileBorder(k,m,curFile) = plot(handles(k,m),[...
          fileStartStamps(curFile) fileStartStamps(curFile)],...
          [yl(1) yl(2)],'Color',[.7 .7 .7],'UserData',...
          sprintf('Start of NilmFile %d',curFile),...
          'HitTest','off');
        set(get(get(startFileBorder(k,m,curFile),'Annotation'),'LegendInformation'),...
            'IconDisplayStyle','off'); % Exclude handle from legend
        set(handles(k,m),'YLim',yl);
        endFileBorder(k,m,curFile) = plot(handles(k,m),[fileEndStamps(curFile)...
          fileEndStamps(curFile)],[yl(1) yl(2)],'Color',[.7 .7 .7],...
          'UserData',sprintf('End of NilmFile %d',curFile),...
          'HitTest','off');
        set(get(get(endFileBorder(k,m,curFile),'Annotation'),'LegendInformation'),...
          'IconDisplayStyle','off'); % Exclude handle from legend
        if k == 1
          textH(1,curFile)=text('Position',[fileStartStamps(curFile),...
            yl(2),1],'String',sprintf('\\rightarrow (%d)',curFile),...
            'VerticalAlignment','top','Parent',handles(k,m));
          textH(2,curFile)=text('Position',[fileEndStamps(curFile),...
            yl(2),1],'String',sprintf('(%d) \\leftarrow',curFile),...
            'HorizontalAlignment','Right','VerticalAlignment','top',...
            'Parent',handles(k,m));
          %textH(curFile,3)=text('Position',[mean([fileStartStamps(curFile) ...
          %  fileEndStamps(curFile)]),yl(2),1],'String',...
          %  sprintf('NilmFile\n %d',curFile),'HorizontalAlignment',...
          %  'Center','VerticalAlignment','top');
        end
      end
      xTickH = findprop(handle(handles(k,m)),'XTick');
      yTickH = findprop(handle(handles(k,m)),'YTick');
      if k==1
        if ~verLessThan('matlab','8.4.0')
          hListenerX = addlistener(handles(k,m),'XTick',...
            'PostSet', @(a,b) textUpdate(a,b,textH));
          hListenerY = addlistener(handles(k,m),'YTick',...
            'PostSet', @(a,b) textUpdate(a,b,textH));
        else
          hListenerX = handle.listener(handles(k,m),xTickH,...
            'PropertyPostSet', @(a,b) textUpdate(a,b,textH));
          hListenerY = handle.listener(handles(k,m),yTickH,...
            'PropertyPostSet', @(a,b) textUpdate(a,b,textH));
        end
        if verLessThan('matlab','8.4.0')
          isTooClose(textH);
        end
      end
      setappdata(handles(k,m),'NFBorder_XTickListener',hListenerX);
      setappdata(handles(k,m),'NFBorder_YTickListener',hListenerY);
    end
  end

  for k=1:size(startFileBorder,1)
    for m=1:size(startFileBorder,2)
      fileBorderGroup = hggroup('Parent',handles(k,m));
      set(startFileBorder(k,m,:),'Parent',fileBorderGroup);
      set(endFileBorder(k,m,:),'Parent',fileBorderGroup);
      % Include these hggroups in the legend:
      set(get(get(fileBorderGroup,'Annotation'),'LegendInformation'),...
        'IconDisplayStyle','off');
      uistack(fileBorderGroup,'bottom');
    end
  end

end

function textUpdate(~,eventData,textH)
  hAxes = eventData.AffectedObject;
  positions=get(textH,'Position');
  borders = axis(hAxes);
  nTextH = numel(textH);
  inside = false(1,nTextH);
  for k=1:nTextH
    pos = positions{k};
    inside(k) = pos(1)<=borders(2) && pos(1)>=borders(1)...
      && pos(2)<=borders(4) && pos(2)>=borders(3);
  end
  set(textH(~inside),'Visible','off');
  set(textH(inside),'Visible','on');
  if verLessThan('matlab','8.4.0')
    isTooClose(textH(inside));
  end
end

function isTooClose(textH)
  if isempty(textH) || numel(textH)<2
    return
  end
  fPairIdx = str2double(regexp(get(textH(1:2:end),'String'),...
    '(\d+)','match','once'));
  sPairIdx = str2double(regexp(get(textH(2:2:end),'String'),...
    '(\d+)','match','once'));
  if fPairIdx(1)~=sPairIdx(1)
    textH(1) = [];
  end
  if fPairIdx(end)~=sPairIdx(end)
    textH(end)=[];
  end
  if numel(textH)<2
    return
  end
  startTextPos = get(textH(1:2:end),'Extent');
  if ~iscell(startTextPos)
    startTextPos = {startTextPos};
  end
  endTextPos = get(textH(2:2:end),'Extent');
  if ~iscell(endTextPos)
    endTextPos = {endTextPos};
  end
  nChecks = numel(startTextPos);
  conflict = false(1,nChecks);
  for k = 1:nChecks
    sText = startTextPos{k};
    sText(3)=sText(3)+sText(1);
    sText(4)=sText(4)+sText(2);
    eText = endTextPos{k};
    eText(3)=eText(3)+eText(1);
    eText(4)=eText(4)+eText(2);
    conflict(k) = ...
      sText(1)<=eText(3) ...
      && sText(1)>=eText(1) ...
      && sText(2)<=eText(4) ...
      && sText(2)>=eText(2) || ...
      sText(3)<=eText(3) ...
      && sText(3)>=eText(1) ...
      && sText(2)<=eText(4) ...
      && sText(2)>=eText(2) || ...
      sText(1)<=eText(3) ...
      && sText(1)>=eText(1) ...
      && sText(4)<=eText(4) ...
      && sText(4)>=eText(2) || ...
      sText(3)<=eText(3) ...
      && sText(3)>=eText(1) ...
      && sText(4)<=eText(4) ...
      && sText(4)>=eText(2);
  end
  set(textH(reshape(repmat(conflict,[2 1]),1,[])),'Visible','off');
end
