This project is a fork of work done by the City Science team at MIT's Media Lab.  It originated as an interactive physical table + simulation for an exhibition at the [Cooper Hewitt Museum](https://www.cooperhewitt.org/2018/11/08/cooper-hewitt-explores-the-future-of-mobility-in-new-exhibition/).

Much credit goes to:
*(in no particular order)*
Kent Larson, Maitane Iruretagoyena, Guadalupe Fernandez, Margaret Church, Gabriela Advincula, Ronan Doorley, Yasushi Sakai, Arnaud Grignard, Ariel Noyman, Luis Alberto Alonso Pastor

See https://github.com/CityScope/CS_Cooper-Hewitt


# Moral Machines

Our future streets will be driven by autonomous vehicles (AVs), and the introduction of AVs presents an opportunity to update how our streets are used.  What societal values should be embedded in the algorithms that drive them?  If properly designed, programmed, and governed, AVs can improve public health, mobility and morality on our future streets.

This is a simulation of two potential futures for autonomous vehicles (AVs):

__1. private__

A world where the streets and their vehicles operate as they do today.  Vehicles are privately owned consumer goods, driven to maximize safety and efficiency for their own passengers.


__2. shared__

A world where AVs operate as shared transit.  They are programmed with new priorities for the streets and their driving algorithms are optimized to maximize public well being.  They always yield to pedestrians and bikers and other vehicles that carry more passengers.  Due to this behavior, __there is an increase in__:

- __road safety__: yielding to higher occupancy vehicles and more vulnerable commuters (bikers and pedestrians) lowers the risk of harm to a greater number of people

- __incentives to bike or walk or use shared transit__: when commutes become safer and more efficient for bikers, walkers, and shared transit, commuters are more likely to choose those modes of transit over private vehicles

- __environmental sustainability__: fewer private vehicles on the road means less pollution


### Agent Based Model

This is an agent based model.
Each car/bike/pedestrian in the simulation is the visualization of a (human) agent's behavior within the model.
The data for the agent model is from people's responses to the US census and National Household Travel Survey.  The subset of data used is for people living in the New York + Newark areas.  For data science details see https://github.com/CityScope/CS_activityBased

Agents in the model take trips within the simulated city.  They travel to and from their residences, offices, and amenities.  These agents make realtime mobility decisions for each trip they take: whether to travel by car, shared transit, bike, or as pedestrians.
These decisions are determined by the agents' personal attributes from the data, the distance they are traveling, and whether they are in the __(1) private__ vs __(2) shared__ world.

#### Traveling in the Private vs Shared Future Worlds
Throughout their trips, agents update how they choose to move on the streets.  Cars, bikes, and pedestrians move differently in the world of private AVs vs shared AVs.

The world of private AVs more closely represents current streets and the rules and values driving them: Vehicles carefully avoid collisions, they yield to other vehicles at intersections, but do not go out of their way to yield to bikes or pedestrians.  

In the world where AVs are designed to operate as shared transit, AV driving algorithms behave differently.  For example, they yield to bikes and pedestrians waiting in intersections.

The differt algorithms for private vs shared AVs leads to differing behaviors on the simulated streets.
In the __shared__ world:
- Agents take shared vehicles instead of private cars.
- Traveling by bike or on foot is more efficient (and safer) because vehicles yield to them.  Thus more agents choose to travel by bike or foot.

The resulting change in congestion and mobility on the streets can be viewed in the simulation.


### Run Code Locally

`source run.sh`
