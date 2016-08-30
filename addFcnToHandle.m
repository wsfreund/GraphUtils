function addFcnToHandle(h,prop,fcn,varargin)
%
% Package NILM_CEPEL.GraphUtils: Function addFcnToHandle
%   Add function to function handle list on property from an handle.
% 
% GraphUtils.addFcnToHandle(h,prop,fcn)
%
%                         ------  Inputs  -------
%
% -> h: handle to be modified
%
% -> prop: property to add the function
%
% -> fcn: function handle to be added.
%

% - Creation Date: Thu, 05 Sep 2013
% - Last Modified: Sun, 10 Aug 2014
% - Author(s): 
%   - W.S.Freund <wsfreund_at_gmail_dot_com>

  oldFcnHandles = get(h,prop);
  if isempty(oldFcnHandles)
    newFcnHandles = fcn;
  else
    if ~iscell(oldFcnHandles)
      oldFcnHandles = {oldFcnHandles};
    end
    newFcnHandles = oldFcnHandles;
    newFcnHandles{end+1} = fcn;
  end
  set(h,prop,newFcnHandles);
end
