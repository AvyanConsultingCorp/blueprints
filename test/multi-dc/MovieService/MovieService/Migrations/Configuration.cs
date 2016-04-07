using MovieService.Models;

namespace MovieService.Migrations
{
    using System;
    using System.Data.Entity;
    using System.Data.Entity.Migrations;
    using System.Linq;

    internal sealed class Configuration : DbMigrationsConfiguration<MovieService.Models.MovieServiceContext>
    {
        public Configuration()
        {
            AutomaticMigrationsEnabled = false;
        }

        protected override void Seed(MovieService.Models.MovieServiceContext context)
        {
            context.Movies.AddOrUpdate(x => x.Id,
                new Movie()
                {
                    Id = 1,
                    Title = "Psycho",
                    Genre = GenreType.Horror,
                    ReleaseYear = 1945,
                    RunningTime = new TimeSpan(2, 10, 20)
                },
                new Movie()
                {
                    Id = 2,
                    Title = "Training Day",
                    Genre = GenreType.Action,
                    ReleaseYear = 2008,
                    RunningTime = new TimeSpan(1, 50, 30)
                },
                new Movie()
                {
                    Id = 3,
                    Title = "Paranormal Activity",
                    Genre = GenreType.Supernatural,
                    ReleaseYear = 2008,
                    RunningTime = new TimeSpan(1, 30, 10)
                }
                );

            context.People.AddOrUpdate(x => x.Id,
                new Person() {Id = 100, PersonType = PersonType.Actor, Name = "Van Damme"},
                new Person() {Id = 101, PersonType = PersonType.Director, Name = "Stephen Fleming"},
                new Person() {Id = 102, PersonType = PersonType.Actor, Name = "Al Pacino"}
                );
        }
    }
}
