function legH = addLegendOutside(axesH,labels,axesToUse);
%
% TODO Help
%

% - Creation Date: Sat, 19 Oct 2013
% - Last Modified: Mon, 16 Jul 2018
% - Author(s):
%   - W.S.Freund <wsfreund_at_gmail_dot_com>

  if nargin < 3
    axesToUse = 1;
  end

  legH=legend(axesH(axesToUse),labels{:},'Location','EastOutside');
  if ~verLessThan('matlab','8.4.0')
    legPos = get(legH,'Position');
  else
    legPos = get(legH,'OuterPosition');
  end
  % newOutPos = get(axesH(1),'OuterPosition');
  if ~verLessThan('matlab','8.4.0')
    set(legH,'Position',[legPos(1) .5-legPos(4)/2 ...
      .99-legPos(1) legPos(4)]);
  end
  for k=1:numel(axesH)
    oldOutPos = get(axesH(k),'OuterPosition');
    set(axesH(k),'OuterPosition',[oldOutPos(1) oldOutPos(2) ...
      oldOutPos(3)-legPos(3)-.01 oldOutPos(4)]);
  end
  if verLessThan('matlab','8.4.0')
    set(legH,'OuterPosition',[legPos(1)+.01 .5-legPos(4)/2 ...
      .99-legPos(1)-.01 legPos(4)]);
  end

end

