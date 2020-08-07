//
//  NRMAInteractionHistory.c
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 5/19/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include "NRMAInteractionHistory.h"


static NRMAInteractionHistoryNode* __list;

void NRMA__insertNode(NRMAInteractionHistoryNode* interaction);


void NRMA__AddInteraction(const char* interactionName, long long timestampMillis)
{
    NRMAInteractionHistoryNode* node  = (NRMAInteractionHistoryNode*)malloc(sizeof(NRMAInteractionHistoryNode));
    if (node != NULL) {
        size_t len = strlen(interactionName);
        if (len < 1) {
            free(node);
            return;
        }
        char* temp = malloc(sizeof(char) * (len+1));
        if (temp == NULL) {
            free(node);
            return; //failure
        }
        strncpy(temp, interactionName,len);
        temp[len] = '\0';
        node->name = temp;
        node->timestampMillis = timestampMillis;

        NRMA__insertNode(node);
    }
}

void NRMA__insertNode(NRMAInteractionHistoryNode* interaction)
{
    interaction->next = __list;
    __list = interaction;
}

void NRMA__setInteractionList(NRMAInteractionHistoryNode* list)
{
    __list = list;
}

NRMAInteractionHistoryNode* NRMA__getInteractionHistoryList()
{
    return __list;
}

void NRMA__deallocInteractionHistoryList()
{
    NRMAInteractionHistoryNode* head = __list;
    __list = NULL;
    while (head != NULL) {
        free((void*)head->name);
        head->name = NULL;
        NRMAInteractionHistoryNode* tmp = head->next;
        free((void*)head);
        head = NULL;
        head = tmp;
    }
}
