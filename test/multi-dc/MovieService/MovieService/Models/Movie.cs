using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace MovieService.Models
{
    public class Movie
    {
        public int Id { get; set; }

        [Required]
        public string Title { get; set; }

        [Required]
        public TimeSpan RunningTime { get; set; }

        [Required]
        public ushort ReleaseYear { get; set; }

        public string Description { get; set; }

        public GenreType Genre { get; set; }

        public IEnumerable<Person> Personnel { get; set; }
    }
}