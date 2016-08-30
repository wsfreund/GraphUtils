function oldMousePos = getCurPointerLocation(unitsType)
%
% Get current mouse pointer location at the specified unitsType. If no
% units specified, the units will be normalized.
%
% oldMousePos = getCurPointerLocation(unitsType)
%

% - Creation Date: Thu, 05 Sep 2013
% - Last Modified: Sun, 10 Aug 2014
% - Author(s): 
%   - W.S.Freund <wsfreund_at_gmail_dot_com>

  if nargin < 1
    unitsType = 'normalized';
  end
  % Get current mouse position:
  oldUnits=get(0,'Units');
  set(0,'Units',unitsType);
  oldMousePos = get(0,'PointerLocation');
  set(0,'Units',oldUnits);
end
