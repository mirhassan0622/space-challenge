# Agent Assignment Algorithm — Model Overview

## Problem Statement

Astra Luxury Travel needs a real-time system that takes incoming customer details and returns a ranked list of travel agents, ordered from the most suitable to the least suitable. The goal is to maximize booking conversion and revenue by matching each customer with the agent who is most likely to close the deal — and close it at the highest possible value.

## Available Data

We have three tables to work with:

1. **space_travel_agents** — Agent profiles including service rating, years of experience, job title, and department.
2. **assignment_history** — Historical record of which agent was assigned to which customer, along with communication method and lead source.
3. **bookings** — Outcome of each assignment: did it convert to a confirmed booking, get cancelled, or is it still pending? Includes destination, launch location, package, and revenue figures.

## Approach

Rather than relying on a single metric, the algorithm uses a **weighted composite scoring model** that evaluates each agent across multiple dimensions relevant to the incoming customer. The idea is straightforward: an agent who has historically performed well with customers that look like the current one should be ranked higher.

### Scoring Dimensions

The model computes five sub-scores for each agent, relative to the incoming customer's attributes:

#### 1. Destination Experience Score (Weight: 25%)
How well has this agent performed specifically with the customer's requested destination? We look at:
- Number of confirmed bookings the agent has closed for that destination
- Their conversion rate for that destination
- Average revenue generated per confirmed booking at that destination

An agent who has closed 10 Mars trips at high revenue is a better match for a Mars-bound customer than one who has only handled Europa bookings.

#### 2. Communication Method Fit (Weight: 20%)
Does the agent have a track record of success with the customer's preferred communication channel (Phone Call vs. Text)? Some agents are better closers on the phone, others convert better over text. We measure:
- Conversion rate by communication method
- Volume of assignments handled via that method

#### 3. Lead Source Fit (Weight: 15%)
Organic and Bought leads behave differently. Organic leads may require less persuasion but expect a more personalized touch. Bought leads may need more aggressive follow-up. We evaluate:
- Agent's conversion rate for the given lead source type
- Average revenue from that lead source

#### 4. Launch Location Experience (Weight: 15%)
Different launch locations may correspond to different regional customer profiles. An agent familiar with customers departing from "Dubai Interplanetary Hub" may better understand the expectations and upsell opportunities for that clientele. We measure:
- Number of confirmed bookings by launch location
- Conversion rate at that location

#### 5. Baseline Agent Quality (Weight: 25%)
Independent of the specific customer, some agents are just better overall. This captures:
- The agent's **AverageCustomerServiceRating** from the agents table
- Their **overall conversion rate** across all assignments
- Their **average total revenue** per confirmed booking
- Their **years of service** (a mild proxy for expertise)

### Composite Score

Each sub-score is normalized to a 0–100 scale, then combined using the weights above:

```
FinalScore = (0.25 × DestinationScore)
           + (0.20 × CommunicationScore)
           + (0.15 × LeadSourceScore)
           + (0.15 × LaunchLocationScore)
           + (0.25 × BaselineQualityScore)
```

### Tiebreaker

If two agents end up with identical composite scores, the tiebreaker favors:
1. Higher AverageCustomerServiceRating
2. More years of service

### Edge Cases

- **New agents with no history**: They receive a baseline score derived from their profile attributes (rating, years of service) plus default mid-range scores for the contextual dimensions. This ensures they aren't permanently buried at the bottom but also aren't ranked above proven performers.
- **Destinations/locations never seen before**: If a destination or launch location doesn't appear in historical data for any agent, the destination and location sub-scores default to a neutral mid-range value, and the ranking is driven primarily by agent quality and communication/lead-source fit.

## Why This Approach

- **It's interpretable.** Each dimension has a clear business rationale. If someone asks "why was Agent X ranked first?", we can point to specific strengths.
- **It's data-driven.** Rather than hand-coding rules, we let historical performance data determine which agents are best for which contexts.
- **It balances specialization with general quality.** An agent who is mediocre overall but fantastic at Mars trips will rank high for Mars customers — but a consistently excellent agent won't be ignored just because they haven't handled that exact destination before.
- **It executes in pure SQL.** No external dependencies, no stored model files — just a query that runs against the existing tables.

## Deliverables

1. **This document** — Model overview and rationale.
2. **`agent_scoring_tables.sql`** — Creates the helper views/tables needed by the algorithm.
3. **`assign_agent.sql`** — The main query. Accepts customer parameters and returns ranked agents.
