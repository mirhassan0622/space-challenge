-- ============================================================
-- agent_scoring_tables.sql
-- Creates the pre-computed scoring views used by the assignment
-- algorithm. These summarize agent performance across multiple
-- dimensions so the main query can score agents efficiently.
-- ============================================================


-- ---------------------------------------------------------
-- View 1: Agent-Level Overall Performance Stats
-- Aggregates each agent's total assignments, confirmed
-- bookings, cancellation count, conversion rate, and
-- average revenue per confirmed booking.
-- ---------------------------------------------------------
DROP VIEW IF EXISTS v_agent_overall_stats;

CREATE VIEW v_agent_overall_stats AS
SELECT
    a.AgentID,
    a.FirstName,
    a.LastName,
    a.AverageCustomerServiceRating,
    a.YearsOfService,
    COUNT(ah.AssignmentID)                                          AS TotalAssignments,
    SUM(CASE WHEN b.BookingStatus = 'Confirmed' THEN 1 ELSE 0 END) AS ConfirmedBookings,
    SUM(CASE WHEN b.BookingStatus = 'Cancelled' THEN 1 ELSE 0 END) AS CancelledBookings,
    -- Conversion rate: confirmed out of all assignments that got a booking outcome
    CASE
        WHEN COUNT(ah.AssignmentID) = 0 THEN 0
        ELSE ROUND(
            SUM(CASE WHEN b.BookingStatus = 'Confirmed' THEN 1.0 ELSE 0 END)
            / COUNT(ah.AssignmentID) * 100
        , 2)
    END                                                             AS ConversionRate,
    -- Average revenue from confirmed bookings only
    COALESCE(
        AVG(CASE WHEN b.BookingStatus = 'Confirmed' THEN b.TotalRevenue END)
    , 0)                                                            AS AvgRevenuePerBooking
FROM
    space_travel_agents a
    LEFT JOIN assignment_history ah ON a.AgentID = ah.AgentID
    LEFT JOIN bookings b            ON ah.AssignmentID = b.AssignmentID
GROUP BY
    a.AgentID, a.FirstName, a.LastName,
    a.AverageCustomerServiceRating, a.YearsOfService;


-- ---------------------------------------------------------
-- View 2: Agent Performance by Destination
-- Shows how each agent performs for each destination they
-- have been assigned to.
-- ---------------------------------------------------------
DROP VIEW IF EXISTS v_agent_destination_stats;

CREATE VIEW v_agent_destination_stats AS
SELECT
    ah.AgentID,
    b.Destination,
    COUNT(*)                                                        AS TotalAttempts,
    SUM(CASE WHEN b.BookingStatus = 'Confirmed' THEN 1 ELSE 0 END) AS ConfirmedCount,
    CASE
        WHEN COUNT(*) = 0 THEN 0
        ELSE ROUND(
            SUM(CASE WHEN b.BookingStatus = 'Confirmed' THEN 1.0 ELSE 0 END)
            / COUNT(*) * 100
        , 2)
    END                                                             AS DestConversionRate,
    COALESCE(
        AVG(CASE WHEN b.BookingStatus = 'Confirmed' THEN b.TotalRevenue END)
    , 0)                                                            AS AvgDestRevenue
FROM
    assignment_history ah
    INNER JOIN bookings b ON ah.AssignmentID = b.AssignmentID
GROUP BY
    ah.AgentID, b.Destination;


-- ---------------------------------------------------------
-- View 3: Agent Performance by Communication Method
-- Shows how each agent converts across Phone Call vs Text.
-- ---------------------------------------------------------
DROP VIEW IF EXISTS v_agent_comm_stats;

CREATE VIEW v_agent_comm_stats AS
SELECT
    ah.AgentID,
    ah.CommunicationMethod,
    COUNT(*)                                                        AS TotalAttempts,
    SUM(CASE WHEN b.BookingStatus = 'Confirmed' THEN 1 ELSE 0 END) AS ConfirmedCount,
    CASE
        WHEN COUNT(*) = 0 THEN 0
        ELSE ROUND(
            SUM(CASE WHEN b.BookingStatus = 'Confirmed' THEN 1.0 ELSE 0 END)
            / COUNT(*) * 100
        , 2)
    END                                                             AS CommConversionRate
FROM
    assignment_history ah
    INNER JOIN bookings b ON ah.AssignmentID = b.AssignmentID
GROUP BY
    ah.AgentID, ah.CommunicationMethod;


-- ---------------------------------------------------------
-- View 4: Agent Performance by Lead Source
-- Shows how each agent converts for Organic vs Bought leads.
-- ---------------------------------------------------------
DROP VIEW IF EXISTS v_agent_lead_stats;

CREATE VIEW v_agent_lead_stats AS
SELECT
    ah.AgentID,
    ah.LeadSource,
    COUNT(*)                                                        AS TotalAttempts,
    SUM(CASE WHEN b.BookingStatus = 'Confirmed' THEN 1 ELSE 0 END) AS ConfirmedCount,
    CASE
        WHEN COUNT(*) = 0 THEN 0
        ELSE ROUND(
            SUM(CASE WHEN b.BookingStatus = 'Confirmed' THEN 1.0 ELSE 0 END)
            / COUNT(*) * 100
        , 2)
    END                                                             AS LeadConversionRate,
    COALESCE(
        AVG(CASE WHEN b.BookingStatus = 'Confirmed' THEN b.TotalRevenue END)
    , 0)                                                            AS AvgLeadRevenue
FROM
    assignment_history ah
    INNER JOIN bookings b ON ah.AssignmentID = b.AssignmentID
GROUP BY
    ah.AgentID, ah.LeadSource;


-- ---------------------------------------------------------
-- View 5: Agent Performance by Launch Location
-- Shows how each agent converts by departure site.
-- ---------------------------------------------------------
DROP VIEW IF EXISTS v_agent_location_stats;

CREATE VIEW v_agent_location_stats AS
SELECT
    ah.AgentID,
    b.LaunchLocation,
    COUNT(*)                                                        AS TotalAttempts,
    SUM(CASE WHEN b.BookingStatus = 'Confirmed' THEN 1 ELSE 0 END) AS ConfirmedCount,
    CASE
        WHEN COUNT(*) = 0 THEN 0
        ELSE ROUND(
            SUM(CASE WHEN b.BookingStatus = 'Confirmed' THEN 1.0 ELSE 0 END)
            / COUNT(*) * 100
        , 2)
    END                                                             AS LocConversionRate
FROM
    assignment_history ah
    INNER JOIN bookings b ON ah.AssignmentID = b.AssignmentID
GROUP BY
    ah.AgentID, b.LaunchLocation;
