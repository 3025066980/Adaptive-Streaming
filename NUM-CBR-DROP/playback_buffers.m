function[slot_index,user_index,allchunk_reception_profile,helper_assign,rrr,served_bits,...
    received_chunkbits,requested_chunkbits,dropped_chunkbits] = playback_buffers(rr,mumu,num_users,N,num_helpers,trans,droplist,zz_bs)
received_chunkbits = zeros(N,num_users);
requested_chunkbits = zeros(N,num_users);
dropped_chunkbits = zeros(N,num_users);
prevchunk_leave_timeplusone = ones(num_helpers+1,num_users,N);
prevchunk_remove_time = zeros(num_helpers+1,num_users);
%actual_trans_profile = zeros(N,num_users);
%******THE GOAL OF THIS FUNCTION IS TO FIND AT WHAT TIME ARE THE CHUNKS
%RECEIVED AT THE USERS. NOT ONLY "WHEN" BUT WE ALSO WANT TO FIND OUT "HOW
%MUCH" OF EACH CHUNK IS RECEIVED WHEN DROPPING IS ALLOWED
allchunk_reception_profile = inf*ones(N,num_users); % this is the matrix which gives us the
                                                    % chunk reception times
                                                    % over one sample path
                                                    % for all the users
helper_assign  = zeros(N,num_users); %indicates which helpers have been assigned the current
                                     % request
rrr = cumsum(rr,3);% This 3 dimensional matrix tells us total arrival bits provided to all queues until
                    % every slot in the sample path.
partialchunk_trans_in_prevslot = zeros(num_helpers+1,num_users);
partialchunk_drop_in_prevslot = zeros(num_helpers+1,num_users);
%******THIS FOR LOOP IS TO FIND OUT THE RECEPTION TIME OF THE CHUNKS OVER
%ONE SAMPLE PATH
for i = 1:N-1
   %if(i>50)
    %   zz_bs(4) = 0;
   %end
   
chunk_reception_time = inf*ones(1,num_users);
chunk_list = repmat(rrr(:,:,i),[1,1,N]);%sum of the amount of bits of all chunks that have been 
%requested by a user until time $i$
helper_index = (rr(:,:,i) > 0); %the helper to which chunk requested at time $i$ has been 
%assigned
[row_ind col_ind] = find(helper_index>0);% find the row index of the helper assign incidence
%matrix, i.e., find the helper number to which the chunk requested at time
%$i$ has been assigned
temporary = zeros(1,num_users);
temporary((zz_bs.*(sum(rr(:,:,i),1)>0))==1) = row_ind;%the index inside temporary singles out
%the users (among the active users) who have requested a non  zero amount
%of bits for chunk requested at slot $i$.
helper_assign(i,:) = temporary;%the helper to which chunk requested by an active user at time 
%slot $i$ has been assigned for delivery
chunk_list = chunk_list.*repmat(helper_index,[1,1,N]);% first single out the helpers to which
%chunk at time slot $i$ has been assigned. now, we have the matrix
%chunk_list which keeps track of the sum of the bits that have been
%requested until time $i$ at every queue. multiplying by the "repeated over
%time" helper_index matrix gives us the sum of all bits that have been
%requested until time $i$ at all the helpers that have been assigned chunks
%at time slot $i$. More precisely, every slot $i$, there is a set of
%helpers (call them active queues) which get assigned current requests. 
%Find out the total amount of
%bits that have been assigned till now to only these 'active queues'
served_bits = cumsum(mumu.*repmat(helper_index,[1,1,N]),3);%the list of total amount of service 
% offered until every slot to the 'active queues' at slot $i$.
served_chunks = (served_bits >= chunk_list);
served_chunks = served_chunks.*repmat(helper_index,[1,1,N]);
tempa22 = helper_index;
tempa2 = repmat(helper_index,[1,1,N]);
                %(served_bits < chunk_list)
service_time_index = cumsum(served_chunks,3);
remove_time = (service_time_index == 1);% time slot in which ith chunk is removed. 
tempa3 = (served_bits < chunk_list);
remove_time_ind = sum(tempa3,3)+1; % This gives the exact slot number when ith chunk is removed
                                   % while remove_time gives us the
                                   % location or the indicator in the 3 D
                                   % matrix
temporar1 = (prevchunk_remove_time < remove_time_ind).*tempa22;%the indices of the active 
                                                               % helpers
                                                               % which had
                                                               % their
                                                               % previous
                                                               % chunk
                                                               % downloaded
                                                               % in an
                                                               % earlier
                                                               % slot
temporar2 = (prevchunk_remove_time == remove_time_ind).*tempa22;% the indices of those helpers
                                                 %among the active helpers
                                                 %which have both the
                                                 %current and previous
                                                 %chunk removed in the
                                                 %same slot. It is obvious
                                                 %in this case that the
                                                 %current chunk is
                                                 %downloaded entriely in
                                                 %one slot itself while
                                                 %some part of the previous
                                                 %chunk has already been
                                                 %downloaded
                                             
                                              
actual_transbits = partialchunk_trans_in_prevslot.*temporar1+...
    sum(trans.*tempa2.*prevchunk_leave_timeplusone.*tempa3,3);
dropped_bits = partialchunk_drop_in_prevslot.*temporar1+...
    sum(droplist.*tempa2.*prevchunk_leave_timeplusone.*tempa3,3);
removed = actual_transbits+dropped_bits;

total_trans_in_slot = sum(trans.*remove_time,3);
total_trans_in_slot(temporar2==1) = partialchunk_trans_in_prevslot(temporar2==1);
total_drop_in_slot = sum(droplist.*remove_time,3);
total_drop_in_slot(temporar2==1) = partialchunk_drop_in_prevslot(temporar2==1);
trans_in_slot = min(total_trans_in_slot,rr(:,:,i).*helper_index-removed);% amount of
%bits of current chunk transmitted in the slot in which the current chunk
%is actually entirely removed
dropped_in_slot = rr(:,:,i).*helper_index-removed-trans_in_slot;% amount of bits of current
%chunk dropped in the slot in which the current chunk is entirely removed
actual_transbits = actual_transbits+trans_in_slot;% total bits of current chunk which actually
%reached the user after removal of chunk
dropped_bits = dropped_bits+dropped_in_slot;%total bits of current chunk which were dropped 
%and did not reach the user
partialchunk_trans_in_prevslot(tempa22) = total_trans_in_slot(tempa22)-trans_in_slot(tempa22);
partialchunk_drop_in_prevslot(tempa22) = total_drop_in_slot(tempa22)-dropped_in_slot(tempa22);
%service_time_index(service_time_index > 1) = 0;
[row,col] = find(service_time_index==1);
quotient = floor(col./num_users);
slot_index = quotient+1;
remainder = mod(col,num_users);
user_index = remainder;
rem = (remainder == 0);
slot_index(rem) = slot_index(rem)-1;
user_index(rem) = num_users;
chunk_reception_time(user_index) = slot_index;
allchunk_reception_profile(i,:) = chunk_reception_time; 
%actual_trans_profile(i,:) = sum(actual_transbits.*helper_index,1); 
tempa = (service_time_index >= 2);
prevchunk_remove_time(tempa22) = remove_time_ind(tempa22);
prevchunk_leave_timeplusone(tempa2) = tempa(tempa2);
received_chunkbits(i,:) = sum(actual_transbits,1);
requested_chunkbits(i,:) = sum(rr(:,:,i),1);
dropped_chunkbits(i,:) = sum(dropped_bits,1);
i
end
