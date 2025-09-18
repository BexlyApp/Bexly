// --------------------------------------------------
    //top scroll
// --------------------------------------------------
document.addEventListener('DOMContentLoaded', function () {
    const headerContainer = document.getElementById('header-container');
    const scrollToTopButton = document.getElementById('scrollToTopButton');
    scrollToTopButton.addEventListener('click', function () {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    });
  
    window.addEventListener('scroll', function () {
        if (document.documentElement.scrollTop > 100) {
            scrollToTopButton.style.display = 'block';
        } else {
            scrollToTopButton.style.display = 'none';
        }
  
        if (document.documentElement.scrollTop > 650) {
              headerContainer.style.display = 'none';
        } else {
              headerContainer.style.display = 'flex';
        }
    })
  });
  
  // --------------------------------------------------
      //left side active class
  // --------------------------------------------------
  const accordionButtons = document.querySelectorAll('.accordion-button');
  const dropdownSubMenuChild = document.querySelectorAll('.accordion-item ul li a');
  
  const removeShowClass = document.querySelectorAll('.remove-show-class');
  const collapseDiv = document.querySelectorAll('.accordion-sub-menu');
  
  
  accordionButtons.forEach(item => {
          item.addEventListener('click', () => {
              accordionButtons.forEach(innerItem => {
                      innerItem.classList.remove('active');
                  });
                  item.classList.add('active');
                  // sub menu child active class remove
                  dropdownSubMenuChild.forEach(innerLink => {
                      innerLink.classList.remove('active');
                  });
          });
  });

  dropdownSubMenuChild.forEach(link => {
      link.addEventListener('click', () => {
          dropdownSubMenuChild.forEach(innerLink => {
              innerLink.classList.remove('active');
          });
          link.classList.add('active');
      });
  });
  
// without sub menu button click, then close collapsed menu
  removeShowClass.forEach(item => {
      item.addEventListener("click", () => {
           collapseDiv.forEach(item => {
              item.classList.remove('show');
          })
      })
  })

//   When page scroll, then active the side bar link
const activeLinkFunc = () => {
    const scrollPosition = window.scrollY || window.pageYOffset;
    if(scrollPosition > 600){
        const setActiveLink = () => {
            // const scrollPosition = window.scrollY || window.pageYOffset;
            const links = document.querySelectorAll('a[href^="#"]');
            
            links.forEach((link) => {
                const targetId = link.getAttribute('href').substring(1);
                const targetDiv = document.getElementById(targetId);
                
                if (targetDiv) {
                    const divPosition = targetDiv.getBoundingClientRect().top + scrollPosition - 100; // Subtract 100px offset, when top 0, then ( -100 remove this code )
                    const divHeight = targetDiv.clientHeight;
                    
                    if (scrollPosition >= divPosition && scrollPosition < divPosition + divHeight) {
                        link.classList.add('active');
                    } else {
                        link.classList.remove('active');
                    }
                }
            });
        }
        
        window.addEventListener('scroll', setActiveLink);
        setActiveLink();
    }
}

window.addEventListener('scroll', activeLinkFunc);
activeLinkFunc();