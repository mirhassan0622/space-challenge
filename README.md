# space-challenge

**Algorithm Challenge**

The year is 2081, and you work for Astra Luxury Travel, a space adventure company that curates premium voyages across the Solar System. From exquisite getaways to the red deserts of Mars, to leisure cruises among Saturn's rings, our team of Space Travel Agents ensures every customer enjoys the perfect experience—from initial Earth departure to safe return. Astra empowers humanity to explore the stars in style and comfort.

**Your Team: Enterprise Intelligence**

The Enterprise Intelligence Department at Astra Luxury Travel is the organization's data-driven nerve center. Our mission is to harness advanced analytics, predictive modeling, and applied AI to maximize revenue for Astra.

**Project**

Your team must develop a real-time SQL assignment algorithm that automatically matches prospective customers with the best travel agent available. Agents not only guide customers through the booking process but also upsell luxury packages, exclusive excursions, and custom accommodations. At the end of each journey, customers rate their experience with their travel agent. Your solution should receive details about a customer (listed below) and return a stack-ranked list of travel agents ordered from best to worst. 

Details known at time of assignment: 
- Customer Name
- Communication Method
- Lead Source
- Destination
- Launch Location

**Requirements**

- Provide a written overview of your model and the approach you chose
- Provide SQL Code that can be executed without errors
    - If your model requires the building of new tables, stored procedures or functions, make sure you provide the SQL code that creates them

---

## Solution

### Files

| File | Purpose |
|------|---------|
| `model_overview.md` | Written overview of the scoring model and approach |
| `agent_scoring_tables.sql` | Creates 5 views that pre-compute agent performance stats |
| `assign_agent.sql` | Main query — accepts customer details, returns ranked agents |

### How to Run

1. **Set up the database** — Create a MySQL database and run the three data table scripts in order:
   ```sql
   SOURCE space_travel_agents SQL Table.txt;
   SOURCE assignment_history SQL Table.txt;
   SOURCE bookings SQL Table.txt;
   ```

2. **Create the scoring views** — Run the helper views script:
   ```sql
   SOURCE agent_scoring_tables.sql;
   ```

3. **Assign an agent** — Open `assign_agent.sql`, change the `SET` variables at the top to match the incoming customer, and execute:
   ```sql
   SET @CustomerName        = 'Jane Doe';
   SET @CommunicationMethod = 'Phone Call';
   SET @LeadSource          = 'Organic';
   SET @Destination         = 'Mars';
   SET @LaunchLocation      = 'Dallas-Fort Worth Launch Complex';
   ```
   Then run the full script. It returns all 30 agents ranked from best match (rank 1) to worst, with a breakdown of each scoring dimension.

### Quick Summary of the Algorithm

The model uses a **weighted composite score** across 5 dimensions:

- **Destination Experience (25%)** — Has this agent closed deals for the requested destination?
- **Communication Method Fit (20%)** — Does the agent convert well via Phone Call or Text?
- **Lead Source Fit (15%)** — How does the agent perform with Organic vs. Bought leads?
- **Launch Location Experience (15%)** — Is the agent familiar with the departure site?
- **Baseline Agent Quality (25%)** — Overall service rating, conversion rate, revenue, and tenure.

See `model_overview.md` for the full explanation.
