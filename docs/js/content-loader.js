class ContentLoader {
    constructor() {
        this.contentContainer = document.getElementById('content-container');
        this.sections = {
            features: 'sections/features.html',
            techStack: 'sections/tech-stack.html',
            installation: 'sections/installation.html',
            projectStructure: 'sections/project-structure.html',
            apiIntegration: 'sections/api-integration.html',
            databaseSchema: 'sections/database-schema.html',
            uiuxDesign: 'sections/uiux-design.html'
        };
    }

    async loadContent() {
        try {
            const content = await this.loadAllSections();
            this.contentContainer.innerHTML = content;
            this.initializeCodeBlocks();
        } catch (error) {
            console.error('Error loading content:', error);
            this.contentContainer.innerHTML = '<p>Error loading content. Please try again later.</p>';
        }
    }

    async loadAllSections() {
        const sectionPromises = Object.entries(this.sections).map(async ([key, path]) => {
            try {
                const response = await fetch(path);
                if (!response.ok) throw new Error(`Failed to load ${path}`);
                const content = await response.text();
                return `<section id="${key}">${content}</section>`;
            } catch (error) {
                console.error(`Error loading section ${key}:`, error);
                return `<section id="${key}"><p>Error loading section content.</p></section>`;
            }
        });

        const sections = await Promise.all(sectionPromises);
        return sections.join('\n');
    }

    initializeCodeBlocks() {
        // Re-initialize Prism.js for syntax highlighting
        if (window.Prism) {
            Prism.highlightAll();
        }
    }
}

// Initialize content loader when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    const loader = new ContentLoader();
    loader.loadContent();
}); 