class Achievement {
  final String id;
  final String title;
  final String description;
  final int reward;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
  });
}

const List<Achievement> achievements = [
  Achievement(
    id: 'first_task',
    title: 'One Small Step',
    description: 'Complete your first task.',
    reward: 25,
  ),
  Achievement(
    id: 'getting_serious',
    title: 'Getting Serious',
    description: 'Complete 10 tasks.',
    reward: 50,
  ),
  Achievement(
    id: 'task_master',
    title: 'Task Master',
    description: 'Complete 25 tasks.',
    reward: 75,
  ),
  Achievement(
    id: 'rising_star',
    title: 'Rising Star',
    description: 'Earn 500 XP.',
    reward: 75,
  ),
  Achievement(
    id: 'hard_worker',
    title: 'Hard Worker',
    description: 'Complete 5 Hard tasks.',
    reward: 75,
  ),
  Achievement(
    id: 'dedicated',
    title: 'Dedicated',
    description: 'Complete tasks on 7 different days.',
    reward: 100,
  ),
];
