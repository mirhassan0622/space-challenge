-- ============================================================
-- assign_agent.sql
-- Main assignment query. Given a customer's details, returns
-- all 30 agents ranked from best fit (rank 1) to worst.
--
-- USAGE:
--   Replace the placeholder values in the SET statements
--   below with the actual customer details, then execute
--   the entire script.
--
-- PREREQUISITES:
--   1. Run the three data table scripts first:
--      - space_travel_agents SQL Table.txt
--      - assignment_history SQL Table.txt
--      - bookings SQL Table.txt
--   2. Run agent_scoring_tables.sql to create the views.
-- ============================================================


-- ---------------------------------------------------------
-- Step 1: Set the incoming customer parameters.
-- Change these values for each new customer request.
-- ---------------------------------------------------------
SET @CustomerName         = 'Jane Doe';
SET @CommunicationMethod  = 'Phone Call';   -- 'Phone Call' or 'Text'
SET @LeadSource           = 'Organic';      -- 'Organic' or 'Bought'
SET @Destination          = 'Mars';
SET @LaunchLocation       = 'Dallas-Fort Worth Launch Complex';


-- ---------------------------------------------------------
-- Step 2: Compute global max values for normalization.
-- We need these so each sub-score is scaled to 0-100.
-- ---------------------------------------------------------

-- Max values across all agents for the baseline quality normalization
SET @MaxRating        = (SELECT MAX(AverageCustomerServiceRating) FROM space_travel_agents);
SET @MaxYears         = (SELECT MAX(YearsOfService) FROM space_travel_agents);
SET @MaxConvRate      = (SELECT MAX(ConversionRate) FROM v_agent_overall_stats);
SET @MaxAvgRevenue    = (SELECT MAX(AvgRevenuePerBooking) FROM v_agent_overall_stats);

-- Max values for destination dimension
SET @MaxDestConv      = (SELECT COALESCE(MAX(DestConversionRate), 1) FROM v_agent_destination_stats WHERE Destination = @Destination);
SET @MaxDestRev       = (SELECT COALESCE(MAX(AvgDestRevenue), 1) FROM v_agent_destination_stats WHERE Destination = @Destination);
SET @MaxDestCount     = (SELECT COALESCE(MAX(ConfirmedCount), 1) FROM v_agent_destination_stats WHERE Destination = @Destination);

-- Max values for communication method dimension
SET @MaxCommConv      = (SELECT COALESCE(MAX(CommConversionRate), 1) FROM v_agent_comm_stats WHERE CommunicationMethod = @CommunicationMethod);
SET @MaxCommCount     = (SELECT COALESCE(MAX(ConfirmedCount), 1) FROM v_agent_comm_stats WHERE CommunicationMethod = @CommunicationMethod);

-- Max values for lead source dimension
SET @MaxLeadConv      = (SELECT COALESCE(MAX(LeadConversionRate), 1) FROM v_agent_lead_stats WHERE LeadSource = @LeadSource);
SET @MaxLeadRev       = (SELECT COALESCE(MAX(AvgLeadRevenue), 1) FROM v_agent_lead_stats WHERE LeadSource = @LeadSource);

-- Max values for launch location dimension
SET @MaxLocConv       = (SELECT COALESCE(MAX(LocConversionRate), 1) FROM v_agent_location_stats WHERE LaunchLocation = @LaunchLocation);
SET @MaxLocCount      = (SELECT COALESCE(MAX(ConfirmedCount), 1) FROM v_agent_location_stats WHERE LaunchLocation = @LaunchLocation);


-- ---------------------------------------------------------
-- Step 3: Score and rank all agents.
-- ---------------------------------------------------------
SELECT
    @CustomerName                                       AS CustomerName,
    a.AgentID,
    CONCAT(a.FirstName, ' ', a.LastName)                AS AgentName,
    a.AverageCustomerServiceRating,
    a.YearsOfService,

    -- =====================================================
    -- Sub-Score 1: Destination Experience (25%)
    -- Rewards agents who have closed bookings for the
    -- requested destination with high conversion and revenue.
    -- =====================================================
    ROUND(
        COALESCE(
            (
                -- 40% weight on conversion rate for this destination
                (ds.DestConversionRate / @MaxDestConv) * 40
                -- 30% weight on average revenue at this destination
              + (ds.AvgDestRevenue    / @MaxDestRev)  * 30
                -- 30% weight on volume of confirmed bookings there
              + (ds.ConfirmedCount    / @MaxDestCount) * 30
            )
        , 30)  -- default score of 30 for agents with no history at this destination
    , 2)                                                AS DestinationScore,

    -- =====================================================
    -- Sub-Score 2: Communication Method Fit (20%)
    -- Rewards agents who convert well via the customer's
    -- preferred communication channel.
    -- =====================================================
    ROUND(
        COALESCE(
            (
                (cs.CommConversionRate / @MaxCommConv)  * 60
              + (cs.ConfirmedCount     / @MaxCommCount) * 40
            )
        , 30)
    , 2)                                                AS CommunicationScore,

    -- =====================================================
    -- Sub-Score 3: Lead Source Fit (15%)
    -- Rewards agents who perform well with this lead type.
    -- =====================================================
    ROUND(
        COALESCE(
            (
                (ls.LeadConversionRate / @MaxLeadConv) * 50
              + (ls.AvgLeadRevenue     / @MaxLeadRev) * 50
            )
        , 30)
    , 2)                                                AS LeadSourceScore,

    -- =====================================================
    -- Sub-Score 4: Launch Location Experience (15%)
    -- Rewards agents familiar with the departure location.
    -- =====================================================
    ROUND(
        COALESCE(
            (
                (locs.LocConversionRate / @MaxLocConv)  * 60
              + (locs.ConfirmedCount    / @MaxLocCount) * 40
            )
        , 30)
    , 2)                                                AS LaunchLocationScore,

    -- =====================================================
    -- Sub-Score 5: Baseline Agent Quality (25%)
    -- General agent quality independent of this customer.
    -- =====================================================
    ROUND(
        (
            -- 30% of this sub-score from customer service rating
            (a.AverageCustomerServiceRating / @MaxRating) * 30
            -- 30% from overall conversion rate
          + (COALESCE(ov.ConversionRate, 0)  / GREATEST(@MaxConvRate, 1)) * 30
            -- 25% from average revenue per booking
          + (COALESCE(ov.AvgRevenuePerBooking, 0) / GREATEST(@MaxAvgRevenue, 1)) * 25
            -- 15% from years of service
          + (a.YearsOfService / @MaxYears) * 15
        )
    , 2)                                                AS BaselineQualityScore,

    -- =====================================================
    -- Final Composite Score
    -- =====================================================
    ROUND(
        -- Destination: 25%
        0.25 * COALESCE(
            (
                (ds.DestConversionRate / @MaxDestConv) * 40
              + (ds.AvgDestRevenue    / @MaxDestRev)  * 30
              + (ds.ConfirmedCount    / @MaxDestCount) * 30
            )
        , 30)
        -- Communication: 20%
      + 0.20 * COALESCE(
            (
                (cs.CommConversionRate / @MaxCommConv)  * 60
              + (cs.ConfirmedCount     / @MaxCommCount) * 40
            )
        , 30)
        -- Lead Source: 15%
      + 0.15 * COALESCE(
            (
                (ls.LeadConversionRate / @MaxLeadConv) * 50
              + (ls.AvgLeadRevenue     / @MaxLeadRev) * 50
            )
        , 30)
        -- Launch Location: 15%
      + 0.15 * COALESCE(
            (
                (locs.LocConversionRate / @MaxLocConv)  * 60
              + (locs.ConfirmedCount    / @MaxLocCount) * 40
            )
        , 30)
        -- Baseline Quality: 25%
      + 0.25 * (
            (a.AverageCustomerServiceRating / @MaxRating) * 30
          + (COALESCE(ov.ConversionRate, 0) / GREATEST(@MaxConvRate, 1)) * 30
          + (COALESCE(ov.AvgRevenuePerBooking, 0) / GREATEST(@MaxAvgRevenue, 1)) * 25
          + (a.YearsOfService / @MaxYears) * 15
        )
    , 2)                                                AS FinalScore

FROM
    space_travel_agents a
    -- Join overall stats
    LEFT JOIN v_agent_overall_stats ov
        ON a.AgentID = ov.AgentID
    -- Join destination-specific stats for the requested destination
    LEFT JOIN v_agent_destination_stats ds
        ON a.AgentID = ds.AgentID
        AND ds.Destination = @Destination
    -- Join communication method stats for the customer's preferred method
    LEFT JOIN v_agent_comm_stats cs
        ON a.AgentID = cs.AgentID
        AND cs.CommunicationMethod = @CommunicationMethod
    -- Join lead source stats for this lead type
    LEFT JOIN v_agent_lead_stats ls
        ON a.AgentID = ls.AgentID
        AND ls.LeadSource = @LeadSource
    -- Join launch location stats
    LEFT JOIN v_agent_location_stats locs
        ON a.AgentID = locs.AgentID
        AND locs.LaunchLocation = @LaunchLocation

ORDER BY
    FinalScore DESC,
    a.AverageCustomerServiceRating DESC,
    a.YearsOfService DESC;
