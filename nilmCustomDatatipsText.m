function tipText = nilmCustomDatatipsText(hObj,event_obj,...
  method)
%
% Package NILM_CEPEL.GraphUtils: Function nilmCustomDatatipsText
%   Set datatip text to use correct date format and set the Y value to
% use specific variable.
%
%   Use it as the datacursormode UpdateFcn.
%
%   You can set it to use two different methods. The default it
% 'fullDate', which will show the full date of the datenum format.
% But you can use the 'distFromCenter' method, which will show the
% distance in day units from 0. For specifying the method, set
% datacursormode UpdateFcn as follows:
%
%  set(datacursormode(gcf),'UpdateFcn',@(a,b) ...
%    GraphUtils.nilmCustomDatatipsText(a,b,'distFromCenter'));
%
%   It will use the string specified as the UserData at the line
% handle as the label for the Y axis value.
%

% - Creation Date: Thu, 05 Sep 2013
% - Last Modified: Sun, 10 Aug 2014
% - Author(s): 
%   - W.S.Freund <wsfreund_at_gmail_dot_com>

try
  if nargin < 3
    method = 'fullDate';
  end

  pos = event_obj.Position;

  switch method
  case 'fullDate'
    tipText=cell(1,3);

    tipText{1} = datestr(pos(1),1);
    tipText{2} = datestr(pos(1),'HH:MM:SS.FFF');
    lineName = get(event_obj.Target,'UserData');
    if(~isempty(lineName))
      if strfind(lineName,'NilmFile')
        tipText{end} = lineName;
      else
        tipText{end} = [lineName ':' num2str(pos(2))];
      end
    else
      tipText{end} = ['Y:' num2str(pos(2))];
    end
  case 'distFromCenter'
    tipText=cell(1,3);
    lineName = get(event_obj.Target,'Tag');
    if(~isempty(lineName))
      tipText{1} = lineName;
    end
    switch sign(pos(1))
    case 1
      tipText{2} = Utils.get_time(pos(1));
    case -1
      tipText{2} = ['-' Utils.get_time(-pos(1))];
    case 0
      tipText{2} = 'Transient Center';
    end
    tipText{2} = ['Sample Reference Time: ' tipText{2}];
    lineVar = get(event_obj.Target,'UserData');
    if ~isempty(lineName)
      tipText{3} = [lineVar ':' num2str(pos(2))];
    else
      tipText{3} = ['Y:' num2str(pos(2))];
    end
  case 'normalAxis'
    tipText=cell(1,2);
    xName = get(event_obj.Target,'userData');
    if ~isempty(xName)
      tipText{1} = [xName ':' num2str(pos(1))];
    else
      tipText{1} = ['X:' num2str(pos(1))];
    end

    lineName = get(event_obj.Target,'Tag');
    if ~isempty(lineName)
      tipText{2} = [lineName ':' num2str(pos(2))];
    else
      tipText{2} = ['Y:' num2str(pos(2))];
    end
  end
catch ext
  keyboard
end

end
