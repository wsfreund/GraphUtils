function bool = isGoodHandle(handles)
%
% Package NILM_CEPEL.GraphUtils: Function isGoodHandle 
%   Check if handles array is valid.
%
%                         ------  Inputs  -------
%
% -> handles: The handles to test.
%

% - Creation Date: Thu, 05 Sep 2013
% - Last Modified: Sun, 10 Aug 2014
% - Author(s): 
%   - W.S.Freund <wsfreund_at_gmail_dot_com>

  bool = ~isempty(handles) && all(handles) && ...
    all(ishandle(handles)) && all(isvalid(handle));

end
