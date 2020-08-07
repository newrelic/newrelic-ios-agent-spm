//
//  NRMAInteractionHistory.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/19/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#ifndef NewRelicAgent_NRMAInteractionHistory_h
#define NewRelicAgent_NRMAInteractionHistory_h

typedef struct {
    const char* name;
    long long timestampMillis;
    void* next;
}NRMAInteractionHistoryNode;

void NRMA__AddInteraction(const char* interactionName, long long timestamp);

NRMAInteractionHistoryNode* NRMA__getInteractionHistoryList(void);

void NRMA__setInteractionList(NRMAInteractionHistoryNode* list);

void NRMA__deallocInteractionHistoryList(void);

#endif
